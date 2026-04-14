//
//  PortraitControlPanel.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import AlloyCore
    import Combine
    import UIKit

    /// 竖屏控制面板
    @MainActor
    public final class PortraitControlPanel: UIView {
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
            btn.isHidden = true
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
            let label = UILabel()
            label.textColor = .white
            label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            label.text = "00:00"
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        public private(set) var slider: ProgressSlider = {
            let v = ProgressSlider()
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        public private(set) var totalTimeLabel: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            label.text = "00:00"
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        public private(set) var fullScreenButton: UIButton = {
            let btn = UIButton(type: .custom)
            let config = UIImage.SymbolConfiguration(pointSize: 14)
            btn.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right", withConfiguration: config), for: .normal)
            btn.tintColor = .white
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }()

        // MARK: - 属性

        public weak var player: Player?
        public var shouldSeekToPlay = false
        public var fullScreenMode: FullScreenMode = .automatic

        // MARK: - Combine

        private let _sliderValueChanging = PassthroughSubject<(value: CGFloat, isForward: Bool), Never>()
        private let _sliderValueChanged = PassthroughSubject<CGFloat, Never>()
        private let _backButtonTap = PassthroughSubject<Void, Never>()
        public var backButtonTapPublisher: AnyPublisher<Void, Never> {
            _backButtonTap.eraseToAnyPublisher()
        }

        public var sliderValueChangingPublisher: AnyPublisher<(value: CGFloat, isForward: Bool), Never> {
            _sliderValueChanging.eraseToAnyPublisher()
        }

        public var sliderValueChangedPublisher: AnyPublisher<CGFloat, Never> {
            _sliderValueChanged.eraseToAnyPublisher()
        }

        // MARK: - 内部

        private var cancellables = Set<AnyCancellable>()
        private var isControlVisible = false

        // MARK: - 初始化

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
            // 顶部工具栏
            let topGradient = GradientView()
            topGradient.translatesAutoresizingMaskIntoConstraints = false
            addSubview(topGradient)
            addSubview(topToolBar)
            topToolBar.addSubview(backButton)
            topToolBar.addSubview(titleLabel)

            // 底部工具栏
            let bottomGradient = GradientView(isTopToBottom: false)
            bottomGradient.translatesAutoresizingMaskIntoConstraints = false
            addSubview(bottomGradient)
            addSubview(bottomToolBar)
            bottomToolBar.addSubview(playPauseButton)
            bottomToolBar.addSubview(currentTimeLabel)
            bottomToolBar.addSubview(slider)
            bottomToolBar.addSubview(totalTimeLabel)
            bottomToolBar.addSubview(fullScreenButton)

            NSLayoutConstraint.activate([
                topGradient.topAnchor.constraint(equalTo: topAnchor),
                topGradient.leadingAnchor.constraint(equalTo: leadingAnchor),
                topGradient.trailingAnchor.constraint(equalTo: trailingAnchor),
                topGradient.heightAnchor.constraint(equalToConstant: 80),

                topToolBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                topToolBar.leadingAnchor.constraint(equalTo: leadingAnchor),
                topToolBar.trailingAnchor.constraint(equalTo: trailingAnchor),
                topToolBar.heightAnchor.constraint(equalToConstant: 44),

                backButton.leadingAnchor.constraint(equalTo: topToolBar.leadingAnchor, constant: 12),
                backButton.centerYAnchor.constraint(equalTo: topToolBar.centerYAnchor),
                backButton.widthAnchor.constraint(equalToConstant: 30),
                backButton.heightAnchor.constraint(equalToConstant: 30),

                titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
                titleLabel.centerYAnchor.constraint(equalTo: topToolBar.centerYAnchor),

                bottomGradient.bottomAnchor.constraint(equalTo: bottomAnchor),
                bottomGradient.leadingAnchor.constraint(equalTo: leadingAnchor),
                bottomGradient.trailingAnchor.constraint(equalTo: trailingAnchor),
                bottomGradient.heightAnchor.constraint(equalToConstant: 80),

                bottomToolBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
                bottomToolBar.leadingAnchor.constraint(equalTo: leadingAnchor),
                bottomToolBar.trailingAnchor.constraint(equalTo: trailingAnchor),
                bottomToolBar.heightAnchor.constraint(equalToConstant: 44),

                playPauseButton.leadingAnchor.constraint(equalTo: bottomToolBar.leadingAnchor, constant: 12),
                playPauseButton.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
                playPauseButton.widthAnchor.constraint(equalToConstant: 30),
                playPauseButton.heightAnchor.constraint(equalToConstant: 30),

                currentTimeLabel.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 8),
                currentTimeLabel.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
                currentTimeLabel.widthAnchor.constraint(equalToConstant: 48),

                fullScreenButton.trailingAnchor.constraint(equalTo: bottomToolBar.trailingAnchor, constant: -12),
                fullScreenButton.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
                fullScreenButton.widthAnchor.constraint(equalToConstant: 30),
                fullScreenButton.heightAnchor.constraint(equalToConstant: 30),

                totalTimeLabel.trailingAnchor.constraint(equalTo: fullScreenButton.leadingAnchor, constant: -8),
                totalTimeLabel.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
                totalTimeLabel.widthAnchor.constraint(equalToConstant: 48),

                slider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 4),
                slider.trailingAnchor.constraint(equalTo: totalTimeLabel.leadingAnchor, constant: -4),
                slider.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
                slider.heightAnchor.constraint(equalToConstant: 30),
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

            // 点击跳转
            slider.tappedPublisher.sink { [weak self] value in
                self?._sliderValueChanged.send(CGFloat(value))
            }.store(in: &cancellables)
        }

        private func setupActions() {
            playPauseButton.addTarget(self, action: #selector(playOrPauseTapped), for: .touchUpInside)
            fullScreenButton.addTarget(self, action: #selector(fullScreenTapped), for: .touchUpInside)
            backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        }

        @objc private func playOrPauseTapped() {
            playOrPause()
        }

        @objc private func fullScreenTapped() {
            guard let player else { return }
            Task { await player.enterFullScreen(!player.isFullScreen, animated: true) }
        }

        @objc private func backTapped() {
            _backButtonTap.send()
        }

        // MARK: - 公开方法

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

        /// 更新全屏状态 UI（返回按钮可见性 + 全屏按钮图标）
        public func updateFullScreenState(isFullScreen: Bool) {
            backButton.isHidden = !isFullScreen
            let config = UIImage.SymbolConfiguration(pointSize: 14)
            let imageName = isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
            fullScreenButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        }

        public func updatePlayButtonState(isPlaying: Bool) {
            let config = UIImage.SymbolConfiguration(pointSize: 16)
            let imageName = isPlaying ? "pause.fill" : "play.fill"
            playPauseButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
            playPauseButton.tintColor = .white
        }

        public func updateTime(current: TimeInterval, total: TimeInterval) {
            currentTimeLabel.text = TimeFormatter.string(from: Int(current))
            totalTimeLabel.text = TimeFormatter.string(from: Int(total))
            if !slider.isDragging, total > 0 {
                slider.value = Float(current / total)
            }
        }

        public func updateBufferTime(_ bufferTime: TimeInterval) {
            guard let player, player.totalTime > 0 else { return }
            slider.bufferValue = Float(bufferTime / player.totalTime)
        }

        public func updateSlider(value: CGFloat, currentTimeString: String) {
            slider.value = Float(value)
            currentTimeLabel.text = currentTimeString
        }

        public func sliderDidEndChanging() {
            // 恢复定时隐藏等
        }

        public func playOrPause() {
            guard let player else { return }
            if player.engine.isPlaying {
                player.engine.pause()
            } else {
                player.engine.play()
            }
        }

        func shouldRespondToGesture(at point: CGPoint, type _: GestureType, touch _: UITouch) -> Bool {
            let bottomRect = bottomToolBar.frame
            let topRect = topToolBar.frame
            // 工具栏区域内的触摸不响应播放器手势
            if isControlVisible, bottomRect.contains(point) || topRect.contains(point) {
                return false
            }
            return true
        }
    }

    // MARK: - GradientView（内部辅助）

    private final class GradientView: UIView {
        private let gradientLayer = CAGradientLayer()
        private let isTopToBottom: Bool

        init(isTopToBottom: Bool = true) {
            self.isTopToBottom = isTopToBottom
            super.init(frame: .zero)
            layer.addSublayer(gradientLayer)
            gradientLayer.colors = [
                UIColor.black.withAlphaComponent(isTopToBottom ? 0.6 : 0).cgColor,
                UIColor.black.withAlphaComponent(isTopToBottom ? 0 : 0.6).cgColor,
            ]
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            gradientLayer.frame = bounds
        }
    }
#endif
