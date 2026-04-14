//
//  LandscapeControlPanel.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import AlloyCore
    import Combine
    import UIKit

    /// 横屏控制面板
    ///
    /// 相比竖屏增加了返回按钮和锁屏按钮。
    @MainActor
    public final class LandscapeControlPanel: UIView {
        // MARK: - 子视图

        public private(set) var topToolBar: UIView = {
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        public private(set) var bottomToolBar: UIView = {
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        public private(set) var backButton: UIButton = {
            let btn = UIButton(type: .custom)
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
            btn.tintColor = .white
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }()

        public private(set) var titleLabel: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.font = .systemFont(ofSize: 15)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        public private(set) var playPauseButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }()

        public private(set) var currentTimeLabel: UILabel = {
            let l = UILabel()
            l.textColor = .white
            l.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            l.text = "00:00"
            l.translatesAutoresizingMaskIntoConstraints = false
            return l
        }()

        public private(set) var slider: ProgressSlider = {
            let v = ProgressSlider()
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        public private(set) var totalTimeLabel: UILabel = {
            let l = UILabel()
            l.textColor = .white
            l.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            l.text = "00:00"
            l.translatesAutoresizingMaskIntoConstraints = false
            return l
        }()

        public private(set) var lockButton: UIButton = {
            let btn = UIButton(type: .custom)
            let config = UIImage.SymbolConfiguration(pointSize: 18)
            btn.setImage(UIImage(systemName: "lock.open.fill", withConfiguration: config), for: .normal)
            btn.tintColor = .white
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }()

        // MARK: - 属性

        public weak var player: Player?
        public var shouldSeekToPlay = false
        public var shouldShowCustomStatusBar = false
        public var fullScreenMode: FullScreenMode = .automatic

        // MARK: - Combine

        private let _sliderValueChanging = PassthroughSubject<(value: CGFloat, isForward: Bool), Never>()
        private let _sliderValueChanged = PassthroughSubject<CGFloat, Never>()
        private let _backButtonTap = PassthroughSubject<Void, Never>()
        public var sliderValueChangingPublisher: AnyPublisher<(value: CGFloat, isForward: Bool), Never> {
            _sliderValueChanging.eraseToAnyPublisher()
        }

        public var sliderValueChangedPublisher: AnyPublisher<CGFloat, Never> {
            _sliderValueChanged.eraseToAnyPublisher()
        }

        public var backButtonTapPublisher: AnyPublisher<Void, Never> {
            _backButtonTap.eraseToAnyPublisher()
        }

        private var cancellables = Set<AnyCancellable>()
        private var isControlVisible = false

        override public init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
            setupSlider()
            setupActions()
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupViews() {
            addSubview(topToolBar)
            addSubview(bottomToolBar)
            addSubview(lockButton)

            topToolBar.addSubview(backButton)
            topToolBar.addSubview(titleLabel)
            bottomToolBar.addSubview(playPauseButton)
            bottomToolBar.addSubview(currentTimeLabel)
            bottomToolBar.addSubview(slider)
            bottomToolBar.addSubview(totalTimeLabel)

            NSLayoutConstraint.activate([
                topToolBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                topToolBar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                topToolBar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                topToolBar.heightAnchor.constraint(equalToConstant: 44),

                backButton.leadingAnchor.constraint(equalTo: topToolBar.leadingAnchor, constant: 12),
                backButton.centerYAnchor.constraint(equalTo: topToolBar.centerYAnchor),
                backButton.widthAnchor.constraint(equalToConstant: 30),
                backButton.heightAnchor.constraint(equalToConstant: 30),

                titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
                titleLabel.centerYAnchor.constraint(equalTo: topToolBar.centerYAnchor),

                bottomToolBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
                bottomToolBar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                bottomToolBar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                bottomToolBar.heightAnchor.constraint(equalToConstant: 44),

                playPauseButton.leadingAnchor.constraint(equalTo: bottomToolBar.leadingAnchor, constant: 12),
                playPauseButton.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
                playPauseButton.widthAnchor.constraint(equalToConstant: 30),
                playPauseButton.heightAnchor.constraint(equalToConstant: 30),

                currentTimeLabel.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 8),
                currentTimeLabel.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
                currentTimeLabel.widthAnchor.constraint(equalToConstant: 52),

                totalTimeLabel.trailingAnchor.constraint(equalTo: bottomToolBar.trailingAnchor, constant: -12),
                totalTimeLabel.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
                totalTimeLabel.widthAnchor.constraint(equalToConstant: 52),

                slider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 4),
                slider.trailingAnchor.constraint(equalTo: totalTimeLabel.leadingAnchor, constant: -4),
                slider.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
                slider.heightAnchor.constraint(equalToConstant: 30),

                lockButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
                lockButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                lockButton.widthAnchor.constraint(equalToConstant: 40),
                lockButton.heightAnchor.constraint(equalToConstant: 40),
            ])
        }

        private func setupSlider() {
            slider.valueChangedPublisher.sink { [weak self] value in
                guard let self else { return }
                self._sliderValueChanging.send((value: CGFloat(value), isForward: self.slider.isForward))
            }.store(in: &cancellables)
            slider.touchEndedPublisher.sink { [weak self] value in
                self?._sliderValueChanged.send(CGFloat(value))
            }.store(in: &cancellables)
        }

        private func setupActions() {
            backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
            playPauseButton.addTarget(self, action: #selector(playOrPauseTapped), for: .touchUpInside)
            lockButton.addTarget(self, action: #selector(lockTapped), for: .touchUpInside)
        }

        @objc private func backTapped() {
            _backButtonTap.send()
        }

        @objc private func playOrPauseTapped() {
            playOrPause()
        }

        @objc private func lockTapped() {
            guard let player else { return }
            player.isScreenLocked.toggle()
            let config = UIImage.SymbolConfiguration(pointSize: 18)
            let name = player.isScreenLocked ? "lock.fill" : "lock.open.fill"
            lockButton.setImage(UIImage(systemName: name, withConfiguration: config), for: .normal)
        }

        // MARK: - 公开方法（与 PortraitControlPanel 对称）

        public func resetControlView() {
            slider.value = 0
            slider.bufferValue = 0
            currentTimeLabel.text = "00:00"
            totalTimeLabel.text = "00:00"
            titleLabel.text = nil
        }

        public func showControlView() {
            isControlVisible = true
            UIView.animate(withDuration: 0.25) {
                self.topToolBar.alpha = 1
                self.bottomToolBar.alpha = 1
                self.lockButton.alpha = 1
            }
        }

        public func hideControlView() {
            isControlVisible = false
            UIView.animate(withDuration: 0.25) {
                self.topToolBar.alpha = 0
                self.bottomToolBar.alpha = 0
            }
        }

        public func show(title: String?, fullScreenMode: FullScreenMode) {
            titleLabel.text = title
            self.fullScreenMode = fullScreenMode
        }

        public func updatePlayButtonState(isPlaying: Bool) {
            let config = UIImage.SymbolConfiguration(pointSize: 16)
            playPauseButton.setImage(UIImage(systemName: isPlaying ? "pause.fill" : "play.fill", withConfiguration: config), for: .normal)
            playPauseButton.tintColor = .white
        }

        public func updateTime(current: TimeInterval, total: TimeInterval) {
            currentTimeLabel.text = TimeFormatter.string(from: Int(current))
            totalTimeLabel.text = TimeFormatter.string(from: Int(total))
            if !slider.isDragging, total > 0 { slider.value = Float(current / total) }
        }

        public func updateBufferTime(_ bufferTime: TimeInterval) {
            guard let player, player.totalTime > 0 else { return }
            slider.bufferValue = Float(bufferTime / player.totalTime)
        }

        public func updateSlider(value: CGFloat, currentTimeString: String) {
            slider.value = Float(value)
            currentTimeLabel.text = currentTimeString
        }

        public func playOrPause() {
            guard let player else { return }
            if player.engine.isPlaying { player.engine.pause() } else { player.engine.play() }
        }

        public func sliderDidEndChanging() {}

        public func updatePresentationSize(_: CGSize) {}
        public func updateOrientation(_: OrientationManager) {}

        func shouldRespondToGesture(at point: CGPoint, type _: GestureType, touch _: UITouch) -> Bool {
            if isControlVisible, bottomToolBar.frame.contains(point) || topToolBar.frame.contains(point) { return false }
            return true
        }
    }
#endif
