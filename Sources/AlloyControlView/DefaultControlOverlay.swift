//
//  DefaultControlOverlay.swift
//  AlloyControlView
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
    /// 实现 ControlOverlay 协议的完整控制逻辑。
    @MainActor
    public final class DefaultControlOverlay: UIView, ControlOverlay {
        // MARK: - ControlOverlay

        public weak var player: Player? {
            didSet {
                portraitPanel.player = player
                landscapePanel.player = player
            }
        }

        // MARK: - 子视图

        public private(set) var portraitPanel = PortraitControlPanel()
        public private(set) var landscapePanel = LandscapeControlPanel()
        public private(set) var bufferingIndicator = BufferingIndicator()
        public private(set) var bottomProgress: ProgressSlider = {
            let v = ProgressSlider()
            v.trackHeight = 1
            v.isThumbHidden = true
            v.isTapEnabled = false
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
            btn.setTitle("加载失败，点击重试", for: .normal)
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
        public var shouldSeekToPlay = true
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
        public var fullScreenMode: FullScreenMode = .automatic

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
        private var autoHideWorkItem: DispatchWorkItem?
        private var cancellables = Set<AnyCancellable>()
        private var volumeBrightnessHUD = VolumeAndBrightnessHUD()

        // MARK: - 初始化

        override public init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
            setupBindings()
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
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
            // 横屏返回按钮
            landscapePanel.backButtonTapPublisher.sink { [weak self] in
                guard let self, let player = self.player else { return }
                Task { await player.enterFullScreen(false, animated: true) }
                self._backButtonTap.send()
            }.store(in: &cancellables)

            // 竖屏返回按钮
            portraitPanel.backButtonTapPublisher.sink { [weak self] in
                guard let self, let player = self.player else { return }
                Task { await player.enterFullScreen(false, animated: true) }
                self._backButtonTap.send()
            }.store(in: &cancellables)

            // 订阅 slider 拖动/点击结束事件，执行 seek
            portraitPanel.sliderValueChangedPublisher.sink { [weak self] value in
                self?.handleSliderSeek(value: value)
            }.store(in: &cancellables)

            landscapePanel.sliderValueChangedPublisher.sink { [weak self] value in
                self?.handleSliderSeek(value: value)
            }.store(in: &cancellables)

            failButton.addTarget(self, action: #selector(failButtonTapped), for: .touchUpInside)
        }

        /// 处理 slider 拖动/点击结束后的 seek
        private func handleSliderSeek(value: CGFloat) {
            guard let player, player.totalTime > 0 else { return }
            let seekTime = player.totalTime * TimeInterval(value)

            // 锁定 slider 位置，seek 期间阻止 playTimePublisher 覆盖
            isSeeking = true
            seekingSliderValue = Float(value)

            Task {
                let success = await player.seek(to: seekTime)
                isSeeking = false
                if success {
                    if shouldSeekToPlay {
                        player.engine.play()
                    }
                } else {
                    // seek 失败，slider 恢复到当前实际播放位置
                    let currentValue = player.totalTime > 0 ? Float(player.currentTime / player.totalTime) : 0
                    portraitPanel.slider.value = currentValue
                    landscapePanel.slider.value = currentValue
                }
            }
        }

        @objc private func failButtonTapped() {
            player?.engine.reloadPlayer()
        }

        // MARK: - 公开方法

        public func show(title: String?, coverURL _: URL? = nil, placeholderImage: UIImage? = nil, fullScreenMode: FullScreenMode) {
            self.fullScreenMode = fullScreenMode
            portraitPanel.show(title: title, fullScreenMode: fullScreenMode)
            landscapePanel.show(title: title, fullScreenMode: fullScreenMode)
            if let placeholder = placeholderImage { coverImageView.image = placeholder }
        }

        public func show(title: String?, coverImage: UIImage?, fullScreenMode: FullScreenMode) {
            self.fullScreenMode = fullScreenMode
            portraitPanel.show(title: title, fullScreenMode: fullScreenMode)
            landscapePanel.show(title: title, fullScreenMode: fullScreenMode)
            if let image = coverImage { coverImageView.image = image }
        }

        public func resetControlView() {
            portraitPanel.resetControlView()
            landscapePanel.resetControlView()
            bottomProgress.value = 0
            bottomProgress.bufferValue = 0
            coverImageView.isHidden = false
            failButton.isHidden = true
            seekHUDView.isHidden = true
            bufferingIndicator.stopAnimating()
        }

        // MARK: - 显示/隐藏控制层

        private func showControlView() {
            isShowing = true
            _controlVisibility.send(true)
            bottomProgress.isHidden = true
            if player?.isFullScreen == true {
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

        // MARK: - ControlOverlay 回调

        public func player(_: Player, didChangePlaybackState state: PlaybackState) {
            portraitPanel.updatePlayButtonState(isPlaying: state == .playing)
            landscapePanel.updatePlayButtonState(isPlaying: state == .playing)

            switch state {
            case .playing:
                failButton.isHidden = true
                bufferingIndicator.stopAnimating()
            case .failed:
                failButton.isHidden = false
                bufferingIndicator.stopAnimating()
            default:
                break
            }
        }

        public func player(_ player: Player, didChangeLoadState state: LoadState) {
            if state.contains(.playthroughOK) || state.contains(.playable) {
                coverImageView.isHidden = true
                bufferingIndicator.stopAnimating()
            }
            if state.contains(.stalled), player.engine.isPlaying {
                bufferingIndicator.startAnimating()
            }
            if state.contains(.prepare) {
                if shouldShowLoadingOnPrepare { bufferingIndicator.startAnimating() }
                if shouldShowControlOnPrepare { showControlView() }
            }
        }

        public func player(_: Player, didUpdateTime currentTime: TimeInterval, totalTime: TimeInterval) {
            // seek 期间保持 slider 在用户拖动的位置，不被旧的 currentTime 覆盖
            if isSeeking {
                return
            }
            portraitPanel.updateTime(current: currentTime, total: totalTime)
            landscapePanel.updateTime(current: currentTime, total: totalTime)
            if !portraitPanel.slider.isDragging, totalTime > 0 {
                bottomProgress.value = Float(currentTime / totalTime)
            }
        }

        public func player(_ player: Player, didUpdateBufferTime bufferTime: TimeInterval) {
            portraitPanel.updateBufferTime(bufferTime)
            landscapePanel.updateBufferTime(bufferTime)
            if player.totalTime > 0 {
                bottomProgress.bufferValue = Float(bufferTime / player.totalTime)
            }
        }

        public func playerDidPlayToEnd(_: Player) {
            // 播放结束后，将两个面板的播放按钮切换为重播图标
            portraitPanel.markPlayEnded()
            landscapePanel.markPlayEnded()
            // 结束时把控制层展示出来，方便用户看到重播按钮
            showControlView()
        }

        public func player(_: Player, willChangeOrientation _: OrientationManager) {
            // 提前切换面板
        }

        public func player(_ player: Player, didChangeOrientation _: OrientationManager) {
            let isLandscape = player.isFullScreen && fullScreenMode != .portrait
            portraitPanel.isHidden = isLandscape
            landscapePanel.isHidden = !isLandscape
            // 竖屏全屏时显示返回按钮
            portraitPanel.updateFullScreenState(isFullScreen: player.isFullScreen)
        }

        // MARK: - 手势回调

        public func gestureSingleTapped(_: GestureManager) {
            if isShowing { hideControlView() } else { showControlView() }
        }

        public func gestureDoubleTapped(_: GestureManager) {
            if player?.isFullScreen == true {
                landscapePanel.playOrPause()
            } else {
                portraitPanel.playOrPause()
            }
        }

        public func gestureBeganPan(_: GestureManager, direction: PanDirection, location _: PanLocation) {
            if direction == .horizontal {
                sumTime = player?.currentTime ?? 0
            }
        }

        public func gestureChangedPan(_: GestureManager, direction: PanDirection, location: PanLocation, velocity: CGPoint) {
            guard let player else { return }
            switch direction {
            case .horizontal:
                sumTime += TimeInterval(velocity.x) / 200
                sumTime = max(0, min(sumTime, player.totalTime))
                let progress = player.totalTime > 0 ? CGFloat(sumTime / player.totalTime) : 0
                let timeString = TimeFormatter.string(from: Int(sumTime))
                portraitPanel.updateSlider(value: progress, currentTimeString: timeString)
                landscapePanel.updateSlider(value: progress, currentTimeString: timeString)
            case .vertical:
                if location == .left {
                    player.brightness -= Float(velocity.y) / 10000
                    volumeBrightnessHUD.update(progress: CGFloat(player.brightness), type: .brightness)
                } else {
                    player.volume -= Float(velocity.y) / 10000
                    volumeBrightnessHUD.update(progress: CGFloat(player.volume), type: .volume)
                }
            default: break
            }
        }

        public func gestureEndedPan(_: GestureManager, direction: PanDirection, location _: PanLocation) {
            guard direction == .horizontal, let player else { return }

            // 锁定 slider 位置
            isSeeking = true
            if player.totalTime > 0 {
                seekingSliderValue = Float(sumTime / player.totalTime)
            }

            Task {
                let success = await player.seek(to: sumTime)
                isSeeking = false
                if success, shouldSeekToPlay {
                    player.engine.play()
                }
                portraitPanel.sliderDidEndChanging()
                landscapePanel.sliderDidEndChanging()
            }
        }

        public func gesturePinched(_: GestureManager, scale: Float) {
            player?.engine.scalingMode = scale > 1 ? .aspectFill : .aspectFit
        }

        public func gestureTriggerCondition(_: GestureManager, type: GestureType, recognizer _: UIGestureRecognizer, touch: UITouch) -> Bool {
            let point = touch.location(in: self)
            if player?.isFullScreen == true {
                return landscapePanel.shouldRespondToGesture(at: point, type: type, touch: touch)
            }
            return portraitPanel.shouldRespondToGesture(at: point, type: type, touch: touch)
        }
    }
#endif
