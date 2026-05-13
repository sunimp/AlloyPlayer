//
//  DefaultControlOverlay.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import AlloyCore
    import Combine
    import UIKit

    /// 默认控制层
    ///
    /// 组装竖屏面板、横屏面板、缓冲指示器、进度条等所有子组件，
    /// 实现 UIKitControlOverlay 协议的完整控制逻辑。
    @MainActor
    public final class DefaultControlOverlay: UIView, UIKitControlOverlay {
        public var actionHandler: ((PlaybackControlAction) -> Void)?

        // MARK: - 子视图

        public private(set) var portraitPanel = PortraitControlPanel()
        public private(set) var landscapePanel = LandscapeControlPanel()
        public private(set) var bufferingIndicator = BufferingIndicator()
        public private(set) var bottomProgress: ProgressSlider = {
            let v = ProgressSlider()
            v.trackHeight = 1
            v.isThumbHidden = true
            v.isTapEnabled = true
            v.hitTestInsets = UIEdgeInsets(top: -12, left: 0, bottom: -10, right: 0)
            v.maximumTrackTintColor = .clear
            v.minimumTrackTintColor = .white
            v.bufferTrackTintColor = UIColor(white: 1, alpha: 0.5)
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        public private(set) var coverImageView: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.translatesAutoresizingMaskIntoConstraints = false
            return iv
        }()

        public private(set) var backgroundImageView: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.translatesAutoresizingMaskIntoConstraints = false
            return iv
        }()

        public private(set) var backgroundEffectView: UIVisualEffectView?
        public private(set) var floatingPanel = FloatingControlPanel()
        public private(set) var failButton: UIButton = {
            let btn = UIButton(type: .system)
            btn.setTitleColor(.white, for: .normal)
            btn.isHidden = true
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }()

        /// 快进 HUD
        public private(set) var seekHUDView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(white: 0, alpha: 0.7)
            v.layer.cornerRadius = 8
            v.isHidden = true
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        public private(set) var seekTimeLabel = UILabel()
        public private(set) var seekProgressView = ProgressSlider()
        public private(set) var seekDirectionImageView = UIImageView()

        // MARK: - 配置

        public var isSeekHUDAnimated = true
        public var isBackgroundEffectVisible = false
        public var shouldSeekToPlay = false
        public var isControlViewVisible: Bool {
            isShowing
        }

        public var autoHideInterval: TimeInterval = 2.5
        public var autoFadeInterval: TimeInterval = 0.25
        public var shouldShowControlOnHorizontalPan = true
        public var shouldShowControlOnPrepare = false
        public var shouldShowLoadingOnPrepare = true
        public var isCustomDisablePanMovingDirection = false
        public var shouldShowCustomStatusBar = false
        public var fullScreenMode: FullscreenMode = .automatic
        public var failureRetryTitle: String = "Failed to load, tap to retry" {
            didSet {
                failButton.setTitle(failureRetryTitle, for: .normal)
            }
        }

        public var timeFormatterConfiguration = TimeFormatter.defaultConfiguration {
            didSet {
                portraitPanel.timeFormatterConfiguration = timeFormatterConfiguration
                landscapePanel.timeFormatterConfiguration = timeFormatterConfiguration
            }
        }

        // MARK: - Combine

        private let _backButtonTap = PassthroughSubject<Void, Never>()
        private let _controlVisibility = PassthroughSubject<Bool, Never>()
        public var backButtonTapPublisher: AnyPublisher<Void, Never> {
            _backButtonTap.eraseToAnyPublisher()
        }

        public var controlVisibilityPublisher: AnyPublisher<Bool, Never> {
            _controlVisibility.eraseToAnyPublisher()
        }

        // MARK: - 内部状态

        private var isShowing = false
        private var isSeeking = false
        private var seekingSliderValue: Float = 0
        private var sumTime: TimeInterval = 0
        private var latestState = PlaybackStateSnapshot(engine: PlaybackEngineSnapshot())
        private var isFullscreen = false
        private var isScreenLocked = false
        private var autoHideWorkItem: DispatchWorkItem?
        private var cancellables = Set<AnyCancellable>()
        private var volumeBrightnessHUD = VolumeAndBrightnessHUD()

        // MARK: - 初始化

        override public init(frame: CGRect) {
            super.init(frame: frame)
            failButton.setTitle(failureRetryTitle, for: .normal)
            setupViews()
            setupBindings()
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            updateControlPanelVisibility(removingAnimations: false)
        }

        private func setupViews() {
            // 背景
            addSubview(backgroundImageView)
            addSubview(coverImageView)

            // 控制面板
            portraitPanel.translatesAutoresizingMaskIntoConstraints = false
            landscapePanel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(portraitPanel)
            addSubview(landscapePanel)
            landscapePanel.isHidden = true

            // 缓冲、失败
            bufferingIndicator.translatesAutoresizingMaskIntoConstraints = false
            addSubview(bufferingIndicator)
            addSubview(failButton)

            // 底部进度
            addSubview(bottomProgress)

            // 快进 HUD
            addSubview(seekHUDView)

            // 音量亮度
            volumeBrightnessHUD.translatesAutoresizingMaskIntoConstraints = false
            addSubview(volumeBrightnessHUD)

            NSLayoutConstraint.activate([
                backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
                backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

                coverImageView.topAnchor.constraint(equalTo: topAnchor),
                coverImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                coverImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                coverImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

                portraitPanel.topAnchor.constraint(equalTo: topAnchor),
                portraitPanel.leadingAnchor.constraint(equalTo: leadingAnchor),
                portraitPanel.trailingAnchor.constraint(equalTo: trailingAnchor),
                portraitPanel.bottomAnchor.constraint(equalTo: bottomAnchor),

                landscapePanel.topAnchor.constraint(equalTo: topAnchor),
                landscapePanel.leadingAnchor.constraint(equalTo: leadingAnchor),
                landscapePanel.trailingAnchor.constraint(equalTo: trailingAnchor),
                landscapePanel.bottomAnchor.constraint(equalTo: bottomAnchor),

                bufferingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
                bufferingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
                bufferingIndicator.widthAnchor.constraint(equalToConstant: 80),
                bufferingIndicator.heightAnchor.constraint(equalToConstant: 80),

                failButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                failButton.centerYAnchor.constraint(equalTo: centerYAnchor),

                bottomProgress.leadingAnchor.constraint(equalTo: leadingAnchor),
                bottomProgress.trailingAnchor.constraint(equalTo: trailingAnchor),
                bottomProgress.bottomAnchor.constraint(equalTo: bottomAnchor),
                bottomProgress.heightAnchor.constraint(equalToConstant: 2),

                seekHUDView.centerXAnchor.constraint(equalTo: centerXAnchor),
                seekHUDView.centerYAnchor.constraint(equalTo: centerYAnchor),
                seekHUDView.widthAnchor.constraint(equalToConstant: 140),
                seekHUDView.heightAnchor.constraint(equalToConstant: 80),

                volumeBrightnessHUD.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
                volumeBrightnessHUD.centerXAnchor.constraint(equalTo: centerXAnchor),
                volumeBrightnessHUD.widthAnchor.constraint(equalToConstant: 200),
                volumeBrightnessHUD.heightAnchor.constraint(equalToConstant: 30),
            ])
        }

        private func setupBindings() {
            portraitPanel.playPauseAction = { [weak self] in
                self?.togglePlayPause()
            }
            portraitPanel.fullscreenAction = { [weak self] in
                self?.actionHandler?(.toggleFullscreen)
            }
            landscapePanel.playPauseAction = { [weak self] in
                self?.togglePlayPause()
            }
            landscapePanel.lockToggleAction = { [weak self] isLocked in
                self?.isScreenLocked = isLocked
            }

            // 横屏返回按钮
            landscapePanel.backButtonTapPublisher.sink { [weak self] in
                guard let self else { return }
                self.actionHandler?(.toggleFullscreen)
                self._backButtonTap.send()
            }.store(in: &cancellables)

            // 竖屏返回按钮
            portraitPanel.backButtonTapPublisher.sink { [weak self] in
                guard let self else { return }
                self.actionHandler?(.toggleFullscreen)
                self._backButtonTap.send()
            }.store(in: &cancellables)

            // 订阅 slider 拖动/点击结束事件，执行 seek
            portraitPanel.slider.touchBeganPublisher.sink { [weak self] _ in
                self?.handleSliderInteractionBegan()
            }.store(in: &cancellables)

            portraitPanel.sliderValueChangedPublisher.sink { [weak self] value in
                self?.handleSliderInteractionEnded(value: value)
            }.store(in: &cancellables)

            landscapePanel.slider.touchBeganPublisher.sink { [weak self] _ in
                self?.handleSliderInteractionBegan()
            }.store(in: &cancellables)

            landscapePanel.sliderValueChangedPublisher.sink { [weak self] value in
                self?.handleSliderInteractionEnded(value: value)
            }.store(in: &cancellables)

            bottomProgress.touchBeganPublisher.sink { [weak self] _ in
                self?.handleSliderInteractionBegan()
            }.store(in: &cancellables)

            bottomProgress.valueChangedPublisher.sink { [weak self] value in
                self?.handleBottomProgressChanging(value: CGFloat(value))
            }.store(in: &cancellables)

            bottomProgress.touchEndedPublisher.sink { [weak self] value in
                self?.handleSliderInteractionEnded(value: CGFloat(value))
            }.store(in: &cancellables)

            bottomProgress.tappedPublisher.sink { [weak self] value in
                self?.handleSliderInteractionEnded(value: CGFloat(value))
            }.store(in: &cancellables)

            failButton.addTarget(self, action: #selector(failButtonTapped), for: .touchUpInside)
        }

        private func handleBottomProgressChanging(value: CGFloat) {
            let totalTime = latestState.engine.duration
            guard totalTime > 0 else { return }
            let currentTime = totalTime * TimeInterval(value)
            let currentTimeString = TimeFormatter.string(from: Int(currentTime), configuration: timeFormatterConfiguration)
            portraitPanel.updateSlider(value: value, currentTimeString: currentTimeString)
            landscapePanel.updateSlider(value: value, currentTimeString: currentTimeString)
        }

        private func handleSliderInteractionBegan() {
            guard isShowing else { return }
            cancelAutoHide()
        }

        private func handleSliderInteractionEnded(value: CGFloat) {
            handleSliderSeek(value: value)
            if isShowing {
                scheduleAutoHide()
            }
        }

        /// 处理 slider 拖动/点击结束后的 seek
        private func handleSliderSeek(value: CGFloat) {
            let totalTime = latestState.engine.duration
            guard totalTime > 0 else { return }
            let seekTime = totalTime * TimeInterval(value)

            // 锁定 slider 位置，seek 期间阻止 playTimePublisher 覆盖
            isSeeking = true
            seekingSliderValue = Float(value)

            actionHandler?(.seek(seekTime))
            if shouldSeekToPlay { actionHandler?(.play) }
            isSeeking = false
        }

        @objc private func failButtonTapped() {
            retryPlayback()
        }

        func retryPlayback() {
            actionHandler?(.replay)
        }

        private func togglePlayPause() {
            latestState.engine.playbackState == .playing
                ? actionHandler?(.pause)
                : actionHandler?(.play)
        }

        // MARK: - 公开方法

        public func show(title: String?, coverURL _: URL? = nil, placeholderImage: UIImage? = nil, fullScreenMode: FullscreenMode) {
            self.fullScreenMode = fullScreenMode
            portraitPanel.show(title: title, fullScreenMode: fullScreenMode)
            landscapePanel.show(title: title, fullScreenMode: fullScreenMode)
            if let placeholder = placeholderImage { coverImageView.image = placeholder }
            showControlView()
        }

        public func show(title: String?, coverImage: UIImage?, fullScreenMode: FullscreenMode) {
            self.fullScreenMode = fullScreenMode
            portraitPanel.show(title: title, fullScreenMode: fullScreenMode)
            landscapePanel.show(title: title, fullScreenMode: fullScreenMode)
            if let image = coverImage { coverImageView.image = image }
            showControlView()
        }

        public func resetControlView() {
            portraitPanel.resetControlView()
            landscapePanel.resetControlView()
            restoreControlPanels()
            bottomProgress.value = 0
            bottomProgress.bufferValue = 0
            bottomProgress.stopLoading()
            coverImageView.isHidden = false
            failButton.isHidden = true
            seekHUDView.isHidden = true
            bufferingIndicator.stopAnimating()
        }

        public func render(state: PlaybackStateSnapshot) {
            latestState = state
            let engine = state.engine
            render(playbackState: engine.playbackState)
            render(loadState: engine.loadState)
            render(currentTime: engine.currentTime, totalTime: engine.duration)
            if engine.duration > 0 {
                bottomProgress.bufferValue = Float(engine.bufferedTime / engine.duration)
                portraitPanel.updateBufferTime(engine.bufferedTime, total: engine.duration)
                landscapePanel.updateBufferTime(engine.bufferedTime, total: engine.duration)
            }
        }

        public func render(fullscreenState: FullscreenState) {
            isFullscreen = fullscreenState == .fullscreen
            updateControlPanelVisibility(removingAnimations: true)
        }

        public func handle(event: PlaybackEvent) {
            guard case let .engine(engineEvent) = event else { return }
            switch engineEvent {
            case .didPlayToEnd:
                portraitPanel.markPlayEnded()
                landscapePanel.markPlayEnded()
                showControlView()
            case .failed:
                showFailureView()
            default:
                break
            }
        }

        private func render(playbackState state: PlaybackState) {
            portraitPanel.updatePlayButtonState(isPlaying: state == .playing)
            landscapePanel.updatePlayButtonState(isPlaying: state == .playing)

            switch state {
            case .playing:
                restoreControlPanels()
                bufferingIndicator.stopAnimating()
            case .paused:
                restoreControlPanels()
            case .failed:
                showFailureView()
                bufferingIndicator.stopAnimating()
            default:
                break
            }
        }

        private func render(loadState state: LoadState) {
            if state.contains(.playthroughOK) || state.contains(.playable) {
                restoreControlPanels()
                coverImageView.isHidden = true
                bufferingIndicator.stopAnimating()
                bottomProgress.stopLoading()
            }
            if state.contains(.stalled), latestState.engine.playbackState == .playing {
                bufferingIndicator.startAnimating()
                bottomProgress.startLoading()
            }
            if state.contains(.preparing) {
                restoreControlPanels()
                if shouldShowLoadingOnPrepare { bufferingIndicator.startAnimating() }
                bottomProgress.startLoading()
                if shouldShowControlOnPrepare { showControlView() }
            }
        }

        private func render(currentTime: TimeInterval, totalTime: TimeInterval) {
            guard !isSeeking else { return }
            portraitPanel.updateTime(current: currentTime, total: totalTime)
            landscapePanel.updateTime(current: currentTime, total: totalTime)
            if !portraitPanel.slider.isDragging, !bottomProgress.isDragging, totalTime > 0 {
                bottomProgress.value = Float(currentTime / totalTime)
            }
        }

        // MARK: - 显示/隐藏控制层

        private func showControlView() {
            isShowing = true
            _controlVisibility.send(true)
            bottomProgress.isHidden = true
            if isFullscreen {
                landscapePanel.showControlView()
            } else {
                portraitPanel.showControlView()
            }
            scheduleAutoHide()
        }

        private func hideControlView() {
            isShowing = false
            _controlVisibility.send(false)
            bottomProgress.isHidden = false
            portraitPanel.hideControlView()
            landscapePanel.hideControlView()
            cancelAutoHide()
        }

        private func scheduleAutoHide() {
            cancelAutoHide()
            let work = DispatchWorkItem { [weak self] in self?.hideControlView() }
            autoHideWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + autoHideInterval, execute: work)
        }

        private func cancelAutoHide() {
            autoHideWorkItem?.cancel()
            autoHideWorkItem = nil
        }

        // MARK: - 手势回调

        public func handle(gesture: GestureEvent) {
            guard !isScreenLocked else { return }
            switch gesture {
            case .singleTap:
                handleSingleTapGesture()
            case .doubleTap:
                handleDoubleTapGesture()
            case let .panBegan(direction, _):
                handlePanBegan(direction: direction)
            case let .panChanged(direction, location, velocity):
                handlePanChanged(direction: direction, location: location, velocity: velocity)
            case let .panEnded(direction, _):
                handlePanEnded(direction: direction)
            case let .pinch(scale):
                actionHandler?(.setScalingMode(scale > 1 ? .aspectFill : .aspectFit))
            case .longPress:
                break
            }
        }

        public func shouldReceiveGesture(_ type: GestureType, recognizer _: UIGestureRecognizer, touch: UITouch) -> Bool {
            let point = touch.location(in: self)
            if isFullscreen {
                return landscapePanel.shouldRespondToGesture(at: point, type: type, touch: touch)
            }
            return portraitPanel.shouldRespondToGesture(at: point, type: type, touch: touch)
        }

        private func handleSingleTapGesture() {
            if isShowing { hideControlView() } else { showControlView() }
        }

        private func handleDoubleTapGesture() {
            if isFullscreen {
                landscapePanel.playOrPause()
            } else {
                portraitPanel.playOrPause()
            }
        }

        private func handlePanBegan(direction: PanDirection) {
            if direction == .horizontal {
                sumTime = latestState.engine.currentTime
            }
        }

        private func handlePanChanged(direction: PanDirection, location: PanLocation, velocity: CGPoint) {
            switch direction {
            case .horizontal:
                sumTime += TimeInterval(velocity.x) / 200
                sumTime = max(0, min(sumTime, latestState.engine.duration))
                let progress = latestState.engine.duration > 0 ? CGFloat(sumTime / latestState.engine.duration) : 0
                let timeString = TimeFormatter.string(from: Int(sumTime), configuration: timeFormatterConfiguration)
                portraitPanel.updateSlider(value: progress, currentTimeString: timeString)
                landscapePanel.updateSlider(value: progress, currentTimeString: timeString)
            case .vertical:
                if location == .left {
                    let brightness = max(0, min(1, UIScreen.main.brightness - CGFloat(velocity.y) / 10000))
                    UIScreen.main.brightness = brightness
                    volumeBrightnessHUD.update(progress: brightness, type: .brightness)
                } else {
                    let volume = max(0, min(1, latestState.engine.volume - Float(velocity.y) / 10000))
                    actionHandler?(.setVolume(volume))
                    volumeBrightnessHUD.update(progress: CGFloat(volume), type: .volume)
                }
            default: break
            }
        }

        private func handlePanEnded(direction: PanDirection) {
            guard direction == .horizontal else { return }

            // 锁定 slider 位置
            isSeeking = true
            if latestState.engine.duration > 0 {
                seekingSliderValue = Float(sumTime / latestState.engine.duration)
            }

            actionHandler?(.seek(sumTime))
            if shouldSeekToPlay { actionHandler?(.play) }
            isSeeking = false
            portraitPanel.sliderDidEndChanging()
            landscapePanel.sliderDidEndChanging()
        }

        private func showFailureView() {
            cancelAutoHide()
            isShowing = false
            _controlVisibility.send(false)
            failButton.isHidden = false
            bottomProgress.isHidden = true
            bottomProgress.stopLoading()
            portraitPanel.isHidden = true
            landscapePanel.isHidden = true
            bringSubviewToFront(failButton)
        }

        private func restoreControlPanels() {
            failButton.isHidden = true
            updateControlPanelVisibility(removingAnimations: false)
        }

        private func updateControlPanelVisibility(removingAnimations: Bool) {
            guard failButton.isHidden else { return }
            let isLandscape = isFullscreen && fullScreenMode != .portrait && bounds.width > bounds.height
            UIView.performWithoutAnimation {
                if removingAnimations {
                    removeAnimationsRecursively(from: portraitPanel)
                    removeAnimationsRecursively(from: landscapePanel)
                    removeAnimationsRecursively(from: bottomProgress)
                }
                portraitPanel.isHidden = isLandscape
                landscapePanel.isHidden = !isLandscape
                portraitPanel.updateFullScreenState(isFullScreen: isFullscreen)
                if removingAnimations { layoutIfNeeded() }
            }
        }

        private func removeAnimationsRecursively(from view: UIView) {
            view.layer.removeAllAnimations()
            view.layer.sublayers?.forEach { $0.removeAllAnimations() }
            view.subviews.forEach { removeAnimationsRecursively(from: $0) }
        }
    }
#endif
