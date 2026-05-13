//
//  PortraitControlPanel.swift
//  AlloyPlayerUIKit
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

        /// 顶部工具栏。
        public private(set) var topToolBar: UIView = {
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        /// 底部工具栏。
        public private(set) var bottomToolBar: UIView = {
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        private(set) var topGradientView: UIView = {
            let v = GradientView()
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        private(set) var bottomGradientView: UIView = {
            let v = GradientView(isTopToBottom: false)
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        /// 返回按钮。
        public private(set) var backButton: UIButton = {
            let btn = UIButton(type: .custom)
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
            btn.tintColor = .white
            btn.isHidden = true
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }()

        /// 标题标签。
        public private(set) var titleLabel: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.font = .systemFont(ofSize: 15)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        /// 播放/暂停按钮。
        public private(set) var playPauseButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }()

        /// 当前播放时间标签。
        public private(set) var currentTimeLabel: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            label.text = TimeFormatter.defaultConfiguration.zeroPlaceholder
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        /// 播放进度滑块。
        public private(set) var slider: ProgressSlider = {
            let v = ProgressSlider()
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        /// 总时长标签。
        public private(set) var totalTimeLabel: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            label.text = TimeFormatter.defaultConfiguration.zeroPlaceholder
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        /// 全屏切换按钮。
        public private(set) var fullScreenButton: UIButton = {
            let btn = UIButton(type: .custom)
            let config = UIImage.SymbolConfiguration(pointSize: 14)
            btn.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right", withConfiguration: config), for: .normal)
            btn.tintColor = .white
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }()

        // MARK: - 属性

        /// 播放/暂停按钮动作回调。
        public var playPauseAction: (() -> Void)?

        /// 全屏按钮动作回调。
        public var fullscreenAction: (() -> Void)?

        /// 拖动跳转结束后是否自动恢复播放。
        public var shouldSeekToPlay = false

        /// 当前全屏模式。
        public var fullScreenMode: FullscreenMode = .automatic

        /// 时间格式化配置。
        public var timeFormatterConfiguration = TimeFormatter.defaultConfiguration {
            didSet {
                resetTimeLabels()
            }
        }

        // MARK: - Combine

        private let _sliderValueChanging = PassthroughSubject<(value: CGFloat, isForward: Bool), Never>()
        private let _sliderValueChanged = PassthroughSubject<CGFloat, Never>()
        private let _backButtonTap = PassthroughSubject<Void, Never>()
        /// 返回按钮点击发布者。
        public var backButtonTapPublisher: AnyPublisher<Void, Never> {
            _backButtonTap.eraseToAnyPublisher()
        }

        /// 滑块值变化中发布者。
        public var sliderValueChangingPublisher: AnyPublisher<(value: CGFloat, isForward: Bool), Never> {
            _sliderValueChanging.eraseToAnyPublisher()
        }

        /// 滑块值变化结束发布者。
        public var sliderValueChangedPublisher: AnyPublisher<CGFloat, Never> {
            _sliderValueChanged.eraseToAnyPublisher()
        }

        // MARK: - 内部

        private var cancellables = Set<AnyCancellable>()
        private var isControlVisible = false
        private var isEnded = false
        private lazy var titleLeadingWithBackButtonConstraint = titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4)
        private lazy var titleLeadingWithoutBackButtonConstraint = titleLabel.leadingAnchor.constraint(equalTo: backButton.leadingAnchor)

        // MARK: - 初始化

        override public init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
            setupSlider()
            setupActions()
        }

        /// 不支持从 Interface Builder 或 Storyboard 创建。
        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupViews() {
            // 顶部工具栏
            addSubview(topGradientView)
            topGradientView.addSubview(topToolBar)
            topToolBar.addSubview(backButton)
            topToolBar.addSubview(titleLabel)

            // 底部工具栏
            addSubview(bottomGradientView)
            bottomGradientView.addSubview(bottomToolBar)
            bottomToolBar.addSubview(playPauseButton)
            bottomToolBar.addSubview(currentTimeLabel)
            bottomToolBar.addSubview(slider)
            bottomToolBar.addSubview(totalTimeLabel)
            bottomToolBar.addSubview(fullScreenButton)

            titleLeadingWithoutBackButtonConstraint.isActive = true

            NSLayoutConstraint.activate([
                topGradientView.topAnchor.constraint(equalTo: topAnchor),
                topGradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
                topGradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
                topGradientView.heightAnchor.constraint(equalToConstant: 80),

                topToolBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                topToolBar.leadingAnchor.constraint(equalTo: topGradientView.leadingAnchor),
                topToolBar.trailingAnchor.constraint(equalTo: topGradientView.trailingAnchor),
                topToolBar.heightAnchor.constraint(equalToConstant: 44),

                backButton.leadingAnchor.constraint(equalTo: topToolBar.leadingAnchor, constant: 12),
                backButton.centerYAnchor.constraint(equalTo: topToolBar.centerYAnchor),
                backButton.widthAnchor.constraint(equalToConstant: 30),
                backButton.heightAnchor.constraint(equalToConstant: 30),

                titleLabel.centerYAnchor.constraint(equalTo: topToolBar.centerYAnchor),

                bottomGradientView.bottomAnchor.constraint(equalTo: bottomAnchor),
                bottomGradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
                bottomGradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
                bottomGradientView.heightAnchor.constraint(equalToConstant: 80),

                bottomToolBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
                bottomToolBar.leadingAnchor.constraint(equalTo: bottomGradientView.leadingAnchor),
                bottomToolBar.trailingAnchor.constraint(equalTo: bottomGradientView.trailingAnchor),
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
            fullscreenAction?()
        }

        @objc private func backTapped() {
            _backButtonTap.send()
        }

        // MARK: - 公开方法

        /// 重置控制面板到初始状态。
        public func resetControlView() {
            slider.value = 0
            slider.bufferValue = 0
            resetTimeLabels()
            titleLabel.text = nil
        }

        /// 显示控制面板。
        public func showControlView() {
            isControlVisible = true
            UIView.animate(withDuration: 0.25) {
                self.topGradientView.alpha = 1
                self.topToolBar.alpha = 1
                self.bottomGradientView.alpha = 1
                self.bottomToolBar.alpha = 1
            }
        }

        /// 隐藏控制面板。
        public func hideControlView() {
            isControlVisible = false
            UIView.animate(withDuration: 0.25) {
                self.topGradientView.alpha = 0
                self.bottomGradientView.alpha = 0
            }
        }

        /// 显示标题并更新全屏模式。
        public func show(title: String?, fullScreenMode: FullscreenMode) {
            titleLabel.text = title
            self.fullScreenMode = fullScreenMode
        }

        /// 更新全屏状态 UI（返回按钮可见性 + 全屏按钮图标）
        public func updateFullScreenState(isFullScreen: Bool) {
            backButton.isHidden = !isFullScreen
            updateTitleLeadingConstraint(isBackButtonVisible: isFullScreen)
            let config = UIImage.SymbolConfiguration(pointSize: 14)
            let imageName = isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
            fullScreenButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        }

        private func updateTitleLeadingConstraint(isBackButtonVisible: Bool) {
            NSLayoutConstraint.deactivate([
                titleLeadingWithBackButtonConstraint,
                titleLeadingWithoutBackButtonConstraint,
            ])
            NSLayoutConstraint.activate([
                isBackButtonVisible ? titleLeadingWithBackButtonConstraint : titleLeadingWithoutBackButtonConstraint,
            ])
        }

        /// 更新播放按钮状态。
        public func updatePlayButtonState(isPlaying: Bool) {
            // 进入播放后清除"已播完"标记，按钮恢复常规播放/暂停语义
            if isPlaying { isEnded = false }
            let config = UIImage.SymbolConfiguration(pointSize: 16)
            let imageName: String
            if isEnded {
                imageName = "arrow.counterclockwise"
            } else {
                imageName = isPlaying ? "pause.fill" : "play.fill"
            }
            playPauseButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
            playPauseButton.tintColor = .white
        }

        /// 标记视频播放已结束，按钮切换为"重播"图标
        public func markPlayEnded() {
            isEnded = true
            updatePlayButtonState(isPlaying: false)
        }

        /// 更新时间显示和播放进度。
        public func updateTime(current: TimeInterval, total: TimeInterval) {
            currentTimeLabel.text = TimeFormatter.string(from: Int(current), configuration: timeFormatterConfiguration)
            totalTimeLabel.text = TimeFormatter.string(from: Int(total), configuration: timeFormatterConfiguration)
            if !slider.isDragging, total > 0 {
                slider.value = Float(current / total)
            }
        }

        /// 更新缓冲时间。
        public func updateBufferTime(_ bufferTime: TimeInterval) {
            updateBufferTime(bufferTime, total: 0)
        }

        /// 按总时长更新缓冲进度。
        public func updateBufferTime(_ bufferTime: TimeInterval, total: TimeInterval) {
            guard total > 0 else { return }
            slider.bufferValue = Float(bufferTime / total)
        }

        /// 更新滑块值和当前时间文本。
        public func updateSlider(value: CGFloat, currentTimeString: String) {
            slider.value = Float(value)
            currentTimeLabel.text = currentTimeString
        }

        /// 通知滑块交互结束。
        public func sliderDidEndChanging() {
            // 恢复定时隐藏等
        }

        private func resetTimeLabels() {
            currentTimeLabel.text = timeFormatterConfiguration.zeroPlaceholder
            totalTimeLabel.text = timeFormatterConfiguration.zeroPlaceholder
        }

        /// 触发播放或暂停动作。
        public func playOrPause() {
            playPauseAction?()
        }

        func shouldRespondToGesture(at point: CGPoint, type _: GestureType, touch _: UITouch) -> Bool {
            let bottomRect = bottomToolBar.convert(bottomToolBar.bounds, to: self)
            let topRect = topToolBar.convert(topToolBar.bounds, to: self)
            // 工具栏区域内的触摸不响应播放器手势
            if isControlVisible, bottomRect.contains(point) || topRect.contains(point) {
                return false
            }
            return true
        }
    }
#endif
