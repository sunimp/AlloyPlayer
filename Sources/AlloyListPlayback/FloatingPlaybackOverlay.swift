//
//  FloatingPlaybackOverlay.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import AlloyUIKit
    import Combine
    import UIKit

    @MainActor
    final class FloatingPlaybackOverlay: UIView, UIKitControlOverlay {
        var actionHandler: ((PlaybackControlAction) -> Void)?
        var closeAction: (() -> Void)?

        private var latestState = PlaybackStateSnapshot(engine: PlaybackEngineSnapshot())
        private var isSeeking = false
        private var cancellables = Set<AnyCancellable>()

        private let overlayView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor(white: 0, alpha: 0.35)
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()

        private let playPauseButton: UIButton = {
            let button = UIButton(type: .system)
            button.tintColor = .white
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()

        private let progressSlider: ProgressSlider = {
            let slider = ProgressSlider()
            slider.trackHeight = 3
            slider.trackCornerRadius = 1.5
            slider.thumbSize = CGSize(width: 14, height: 14)
            slider.minimumTrackTintColor = .white
            slider.maximumTrackTintColor = UIColor(white: 1, alpha: 0.28)
            slider.bufferTrackTintColor = UIColor(white: 1, alpha: 0.45)
            slider.translatesAutoresizingMaskIntoConstraints = false
            return slider
        }()

        private let timeLabel: UILabel = {
            let label = UILabel()
            label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            label.textColor = .white
            label.text = "00:00 / 00:00"
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private let closeButton: UIButton = {
            let button = UIButton(type: .custom)
            let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
            button.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
            button.tintColor = .white
            button.backgroundColor = UIColor.black.withAlphaComponent(0.48)
            button.layer.cornerRadius = 15
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
            setupBindings()
            updatePlayButton(isPlaying: false)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func resetControlView() {
            latestState = PlaybackStateSnapshot(engine: PlaybackEngineSnapshot())
            progressSlider.value = 0
            progressSlider.bufferValue = 0
            timeLabel.text = "00:00 / 00:00"
            updatePlayButton(isPlaying: false)
        }

        func render(state: PlaybackStateSnapshot) {
            latestState = state
            let engine = state.engine
            updatePlayButton(isPlaying: engine.playbackState == .playing)
            renderProgress(currentTime: engine.currentTime, duration: engine.duration)
            renderTime(currentTime: engine.currentTime, duration: engine.duration)

            if engine.duration > 0 {
                progressSlider.bufferValue = Float(engine.bufferedTime / engine.duration)
            } else {
                progressSlider.bufferValue = 0
            }

            if engine.loadState.contains(.stalled) || engine.loadState.contains(.preparing) {
                progressSlider.startLoading()
            } else {
                progressSlider.stopLoading()
            }
        }

        func render(fullscreenState _: FullscreenState) {}

        func handle(event: PlaybackEvent) {
            guard case let .engine(engineEvent) = event else { return }
            if case .didPlayToEnd = engineEvent {
                updatePlayButton(imageName: "arrow.counterclockwise")
            }
        }

        func handle(gesture _: GestureEvent) {}

        func shouldReceiveGesture(_: GestureType, recognizer _: UIGestureRecognizer, touch: UITouch) -> Bool {
            var view = touch.view
            while let current = view, current !== self {
                if current is UIControl || current is ProgressSlider {
                    return false
                }
                view = current.superview
            }
            return false
        }

        private func setupViews() {
            backgroundColor = .clear
            addSubview(overlayView)
            addSubview(playPauseButton)
            addSubview(progressSlider)
            addSubview(timeLabel)
            addSubview(closeButton)

            NSLayoutConstraint.activate([
                overlayView.topAnchor.constraint(equalTo: topAnchor),
                overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
                overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
                overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),

                closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
                closeButton.widthAnchor.constraint(equalToConstant: 30),
                closeButton.heightAnchor.constraint(equalToConstant: 30),

                playPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                playPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                playPauseButton.widthAnchor.constraint(equalToConstant: 58),
                playPauseButton.heightAnchor.constraint(equalToConstant: 58),

                progressSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                progressSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                progressSlider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                progressSlider.heightAnchor.constraint(equalToConstant: 30),

                timeLabel.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
                timeLabel.bottomAnchor.constraint(equalTo: progressSlider.topAnchor, constant: -2),
            ])
        }

        private func setupBindings() {
            closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
            playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)

            progressSlider.touchBeganPublisher.sink { [weak self] _ in
                self?.isSeeking = true
            }.store(in: &cancellables)

            progressSlider.valueChangedPublisher.sink { [weak self] value in
                self?.updateProgressPreview(value: value)
            }.store(in: &cancellables)

            progressSlider.touchEndedPublisher.sink { [weak self] value in
                self?.commitSeek(value: value)
            }.store(in: &cancellables)

            progressSlider.tappedPublisher.sink { [weak self] value in
                self?.commitSeek(value: value)
            }.store(in: &cancellables)
        }

        private func renderProgress(currentTime: TimeInterval, duration: TimeInterval) {
            guard !isSeeking, !progressSlider.isDragging else { return }
            progressSlider.value = duration > 0 ? Float(currentTime / duration) : 0
        }

        private func renderTime(currentTime: TimeInterval, duration: TimeInterval) {
            let current = TimeFormatter.string(from: Int(currentTime))
            let total = TimeFormatter.string(from: Int(duration))
            timeLabel.text = "\(current) / \(total)"
        }

        private func updateProgressPreview(value: Float) {
            guard latestState.engine.duration > 0 else { return }
            progressSlider.value = min(max(value, 0), 1)
            renderTime(
                currentTime: latestState.engine.duration * TimeInterval(value),
                duration: latestState.engine.duration
            )
        }

        private func commitSeek(value: Float) {
            defer { isSeeking = false }
            let duration = latestState.engine.duration
            guard duration > 0 else { return }
            actionHandler?(.seek(duration * TimeInterval(value)))
            if latestState.engine.playbackState == .playing {
                actionHandler?(.play)
            }
        }

        private func updatePlayButton(isPlaying: Bool) {
            updatePlayButton(imageName: isPlaying ? "pause.fill" : "play.fill")
        }

        private func updatePlayButton(imageName: String) {
            let configuration = UIImage.SymbolConfiguration(pointSize: 42, weight: .regular)
            playPauseButton.setImage(UIImage(systemName: imageName, withConfiguration: configuration), for: .normal)
        }

        @objc private func closeButtonTapped() {
            closeAction?()
        }

        @objc private func playPauseButtonTapped() {
            if latestState.engine.playbackState == .playing {
                actionHandler?(.pause)
            } else if latestState.engine.currentTime >= latestState.engine.duration, latestState.engine.duration > 0 {
                actionHandler?(.replay)
            } else {
                actionHandler?(.play)
            }
        }
    }
#endif
