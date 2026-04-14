//
//  Player.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import Combine
    import UIKit

    /// 播放器主控制器
    ///
    /// 协调播放引擎（PlaybackEngine）、控制层（ControlOverlay）、
    /// 手势管理（GestureManager）和旋转管理（OrientationManager）。
    @MainActor
    public final class Player {
        // MARK: - 组件

        /// 容器视图
        public weak var containerView: UIView? {
            didSet { layoutPlayerSubViews() }
        }

        /// 播放引擎
        public var engine: PlaybackEngine {
            didSet { setupEngine() }
        }

        /// 控制层
        public var controlOverlay: (UIView & ControlOverlay)? {
            didSet {
                oldValue?.removeFromSuperview()
                controlOverlay?.player = self
                layoutPlayerSubViews()
            }
        }

        /// 旋转管理器
        public private(set) var orientationManager = OrientationManager()

        /// 手势管理器
        public private(set) var gestureManager = GestureManager()

        /// 系统事件观察者
        public internal(set) var systemEventObserver: SystemEventObserver?

        /// 挂载模式
        public private(set) var attachmentMode: AttachmentMode

        // MARK: - 播放状态

        /// 当前播放时间
        public var currentTime: TimeInterval {
            engine.currentTime
        }

        /// 总时长
        public var totalTime: TimeInterval {
            engine.totalTime
        }

        /// 缓冲时长
        public var bufferTime: TimeInterval {
            engine.bufferTime
        }

        /// 播放进度 (0...1)
        public var progress: Float {
            guard totalTime > 0 else { return 0 }
            return Float(currentTime / totalTime)
        }

        /// 缓冲进度 (0...1)
        public var bufferProgress: Float {
            guard totalTime > 0 else { return 0 }
            return Float(bufferTime / totalTime)
        }

        /// 是否全屏
        public var isFullScreen: Bool {
            orientationManager.isFullScreen
        }

        // MARK: - 播放控制

        /// 音量
        public var volume: Float {
            get { engine.volume }
            set { engine.volume = newValue }
        }

        /// 静音
        public var isMuted: Bool {
            get { engine.isMuted }
            set { engine.isMuted = newValue }
        }

        /// 屏幕亮度
        public var brightness: Float {
            get { Float(UIScreen.main.brightness) }
            set { UIScreen.main.brightness = CGFloat(newValue) }
        }

        /// 播放速率
        public var rate: Float {
            get { engine.rate }
            set { engine.rate = newValue }
        }

        // MARK: - 资源管理

        /// 当前播放 URL
        public var assetURL: URL? {
            get { engine.assetURL }
            set {
                engine.assetURL = newValue
                if newValue != nil {
                    setupNotification()
                    engine.prepareToPlay()
                }
            }
        }

        /// 播放列表
        public var assetURLs: [URL]?

        /// 当前播放索引
        public var currentPlayIndex: Int = 0

        /// 是否为第一个资源
        public var isFirstAsset: Bool {
            currentPlayIndex == 0
        }

        /// 是否为最后一个资源
        public var isLastAsset: Bool {
            guard let urls = assetURLs else { return true }
            return currentPlayIndex >= urls.count - 1
        }

        // MARK: - 行为配置

        /// 恢复播放记录
        public var shouldResumePlayRecord = false

        /// 进入后台时暂停
        public var pauseWhenAppResignActive = true

        /// 被外部事件暂停
        public var isPausedByEvent = false

        /// VC 是否不可见
        public var isViewControllerDisappear = false {
            didSet {
                if isViewControllerDisappear {
                    removeDeviceOrientationObserver()
                } else {
                    addDeviceOrientationObserver()
                }
            }
        }

        /// 自定义音频会话
        public var useCustomAudioSession = false

        /// 停止时退出全屏
        public var exitFullScreenWhenStop = true

        // MARK: - 锁屏 & 状态栏

        /// 锁屏
        public var isScreenLocked: Bool {
            get { orientationManager.isScreenLocked }
            set {
                orientationManager.isScreenLocked = newValue
                controlOverlay?.player(self, didChangeLockState: newValue)
            }
        }

        /// 状态栏隐藏
        public var isStatusBarHidden: Bool {
            get { orientationManager.isFullScreenStatusBarHidden }
            set { orientationManager.isFullScreenStatusBarHidden = newValue }
        }

        /// 全屏状态栏样式
        public var fullScreenStatusBarStyle: UIStatusBarStyle {
            get { orientationManager.fullScreenStatusBarStyle }
            set { orientationManager.fullScreenStatusBarStyle = newValue }
        }

        /// 全屏状态栏动画
        public var fullScreenStatusBarAnimation: UIStatusBarAnimation {
            get { orientationManager.fullScreenStatusBarAnimation }
            set { orientationManager.fullScreenStatusBarAnimation = newValue }
        }

        // MARK: - 手势配置

        /// 禁用的手势类型
        public var disabledGestureTypes: DisableGestureTypes {
            get { gestureManager.disabledGestureTypes }
            set { gestureManager.disabledGestureTypes = newValue }
        }

        /// 禁用的滑动方向
        public var disabledPanMovingDirection: DisablePanMovingDirection {
            get { gestureManager.disabledPanMovingDirection }
            set { gestureManager.disabledPanMovingDirection = newValue }
        }

        // MARK: - Combine 事件流

        /// 播放状态变化（透传 engine）
        public var playbackStatePublisher: AnyPublisher<PlaybackState, Never> {
            engine.statePublisher
        }

        /// 加载状态变化
        public var loadStatePublisher: AnyPublisher<LoadState, Never> {
            engine.loadStatePublisher
        }

        /// 播放时间变化
        public var playTimePublisher: AnyPublisher<(current: TimeInterval, total: TimeInterval), Never> {
            engine.playTimePublisher
        }

        /// 缓冲时间变化
        public var bufferTimePublisher: AnyPublisher<TimeInterval, Never> {
            engine.bufferTimePublisher
        }

        /// 播放失败
        public var playFailedPublisher: AnyPublisher<any Error, Never> {
            engine.playFailedPublisher
        }

        /// 播放完成
        public var didPlayToEndPublisher: AnyPublisher<Void, Never> {
            engine.didPlayToEndPublisher
        }

        /// 视频尺寸变化
        public var presentationSizePublisher: AnyPublisher<CGSize, Never> {
            engine.presentationSizePublisher
        }

        /// 即将旋转
        public var orientationWillChangePublisher: AnyPublisher<Bool, Never> {
            orientationManager.orientationWillChangePublisher
        }

        /// 旋转完成
        public var orientationDidChangePublisher: AnyPublisher<Bool, Never> {
            orientationManager.orientationDidChangePublisher
        }

        // MARK: - 内部状态

        var cancellables = Set<AnyCancellable>()
        private var volumeSlider: UISlider?
        private static var playRecords: [String: TimeInterval] = [:]

        // MARK: - 列表播放存储属性（供 Player+ScrollView 扩展使用）

        weak var scrollView: UIScrollView?
        var _containerViewTag: Int = 0
        var _floatingView: FloatingView?
        var _isFloatingViewVisible: Bool = false
        var _shouldAutoPlay: Bool = true
        var _autoPlayOnWWAN: Bool = false
        var _playingIndexPath: IndexPath?
        var _shouldPlayIndexPath: IndexPath?
        var _stopWhileNotVisible: Bool = true
        var _disappearPercent: CGFloat = 0.8
        var _appearPercent: CGFloat = 0.0
        var _sectionAssetURLs: [[URL]]?

        /// 列表播放事件 Subjects
        let _playerAppearing = PassthroughSubject<(IndexPath, CGFloat), Never>()
        let _playerDisappearing = PassthroughSubject<(IndexPath, CGFloat), Never>()
        let _playerWillAppear = PassthroughSubject<IndexPath, Never>()
        let _playerDidAppear = PassthroughSubject<IndexPath, Never>()
        let _playerWillDisappear = PassthroughSubject<IndexPath, Never>()
        let _playerDidDisappear = PassthroughSubject<IndexPath, Never>()
        let _scrollViewDidEndScrolling = PassthroughSubject<IndexPath, Never>()

        // MARK: - 初始化

        /// 普通模式初始化
        public init(engine: PlaybackEngine, containerView: UIView) {
            self.engine = engine
            attachmentMode = .view
            self.containerView = containerView
            commonInit()
        }

        /// 列表模式初始化（通过 tag 查找容器）
        public init(scrollView: UIScrollView, engine: PlaybackEngine, containerViewTag: Int) {
            self.engine = engine
            attachmentMode = .cell
            self.scrollView = scrollView
            _containerViewTag = containerViewTag
            commonInit()
        }

        /// 列表模式初始化（直接传入容器）
        public init(scrollView: UIScrollView, engine: PlaybackEngine, containerView: UIView) {
            self.engine = engine
            attachmentMode = .cell
            self.scrollView = scrollView
            self.containerView = containerView
            commonInit()
        }

        private func commonInit() {
            setupEngine()
            setupGesture()
            setupOrientation()
            configureVolume()
            ReachabilityMonitor.shared.startMonitoring()
            subscribeReachability()
        }

        deinit {
            MainActor.assumeIsolated {
                engine.stop()
                systemEventObserver?.stopObserving()
            }
        }

        // MARK: - 内部 Setup

        private func setupEngine() {
            // 移除旧手势
            gestureManager.detach(from: engine.renderView)
            // 绑定新手势
            gestureManager.attach(to: engine.renderView)
            // 订阅引擎事件
            subscribeEngine()
            // 布局
            layoutPlayerSubViews()
        }

        private func setupGesture() {
            // 手势回调转发给 controlOverlay
            gestureManager.triggerCondition = { [weak self] type, recognizer, touch in
                guard let self, let overlay = self.controlOverlay else { return true }
                return overlay.gestureTriggerCondition(self.gestureManager, type: type, recognizer: recognizer, touch: touch)
            }

            gestureManager.singleTapPublisher.sink { [weak self] in
                guard let self else { return }
                self.controlOverlay?.gestureSingleTapped(self.gestureManager)
            }.store(in: &cancellables)

            gestureManager.doubleTapPublisher.sink { [weak self] in
                guard let self else { return }
                self.controlOverlay?.gestureDoubleTapped(self.gestureManager)
            }.store(in: &cancellables)

            gestureManager.panBeganPublisher.sink { [weak self] event in
                guard let self else { return }
                self.controlOverlay?.gestureBeganPan(self.gestureManager, direction: event.direction, location: event.location)
            }.store(in: &cancellables)

            gestureManager.panChangedPublisher.sink { [weak self] event in
                guard let self else { return }
                self.controlOverlay?.gestureChangedPan(self.gestureManager, direction: event.direction, location: event.location, velocity: event.velocity)
            }.store(in: &cancellables)

            gestureManager.panEndedPublisher.sink { [weak self] event in
                guard let self else { return }
                self.controlOverlay?.gestureEndedPan(self.gestureManager, direction: event.direction, location: event.location)
            }.store(in: &cancellables)

            gestureManager.pinchPublisher.sink { [weak self] scale in
                guard let self else { return }
                self.controlOverlay?.gesturePinched(self.gestureManager, scale: scale)
            }.store(in: &cancellables)

            gestureManager.longPressPublisher.sink { [weak self] state in
                guard let self else { return }
                self.controlOverlay?.longPressed(self.gestureManager, state: state)
            }.store(in: &cancellables)
        }

        private func setupOrientation() {
            if let containerView {
                orientationManager.updateViews(renderView: engine.renderView, containerView: containerView)
            }
            orientationManager.orientationWillChangePublisher.sink { [weak self] _ in
                guard let self else { return }
                self.controlOverlay?.player(self, willChangeOrientation: self.orientationManager)
            }.store(in: &cancellables)

            orientationManager.orientationDidChangePublisher.sink { [weak self] _ in
                guard let self else { return }
                self.controlOverlay?.player(self, didChangeOrientation: self.orientationManager)
                self.layoutPlayerSubViews()
            }.store(in: &cancellables)
        }

        private func subscribeEngine() {
            // 清理旧订阅
            cancellables.removeAll()
            setupGesture()
            setupOrientation()

            engine.statePublisher.sink { [weak self] state in
                guard let self else { return }
                self.controlOverlay?.player(self, didChangePlaybackState: state)
            }.store(in: &cancellables)

            engine.loadStatePublisher.sink { [weak self] state in
                guard let self else { return }
                self.controlOverlay?.player(self, didChangeLoadState: state)
            }.store(in: &cancellables)

            engine.playTimePublisher.sink { [weak self] time in
                guard let self else { return }
                self.controlOverlay?.player(self, didUpdateTime: time.current, totalTime: time.total)
            }.store(in: &cancellables)

            engine.bufferTimePublisher.sink { [weak self] bufferTime in
                guard let self else { return }
                self.controlOverlay?.player(self, didUpdateBufferTime: bufferTime)
            }.store(in: &cancellables)

            engine.prepareToPlayPublisher.sink { [weak self] url in
                guard let self else { return }
                self.controlOverlay?.player(self, prepareToPlay: url)
            }.store(in: &cancellables)

            engine.playFailedPublisher.sink { [weak self] error in
                guard let self else { return }
                self.controlOverlay?.player(self, didFailWithError: error)
            }.store(in: &cancellables)

            engine.didPlayToEndPublisher.sink { [weak self] in
                guard let self else { return }
                self.controlOverlay?.playerDidPlayToEnd(self)
            }.store(in: &cancellables)

            engine.presentationSizePublisher.sink { [weak self] size in
                guard let self else { return }
                self.orientationManager.presentationSize = size
                self.controlOverlay?.player(self, didChangePresentationSize: size)
            }.store(in: &cancellables)
        }

        private func subscribeReachability() {
            ReachabilityMonitor.shared.statusPublisher.sink { [weak self] status in
                guard let self else { return }
                self.controlOverlay?.player(self, didChangeReachability: status)
            }.store(in: &cancellables)
        }

        func setupNotification() {
            systemEventObserver?.stopObserving()
            let observer = SystemEventObserver()
            systemEventObserver = observer
            observer.startObserving()

            observer.willResignActivePublisher.sink { [weak self] in
                guard let self, self.pauseWhenAppResignActive else { return }
                self.isPausedByEvent = true
                self.engine.pause()
            }.store(in: &cancellables)

            observer.didBecomeActivePublisher.sink { [weak self] in
                guard let self, self.isPausedByEvent else { return }
                self.isPausedByEvent = false
                if self.engine.shouldAutoPlay {
                    self.engine.play()
                }
            }.store(in: &cancellables)
        }

        private func configureVolume() {
            // 系统音量控制
        }

        func layoutPlayerSubViews() {
            guard let containerView else { return }
            let renderView = engine.renderView

            if renderView.superview !== containerView {
                containerView.addSubview(renderView)
            }
            renderView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                renderView.topAnchor.constraint(equalTo: containerView.topAnchor),
                renderView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                renderView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                renderView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ])

            if let overlay = controlOverlay {
                if overlay.superview !== renderView {
                    renderView.addSubview(overlay)
                }
                overlay.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    overlay.topAnchor.constraint(equalTo: renderView.topAnchor),
                    overlay.leadingAnchor.constraint(equalTo: renderView.leadingAnchor),
                    overlay.trailingAnchor.constraint(equalTo: renderView.trailingAnchor),
                    overlay.bottomAnchor.constraint(equalTo: renderView.bottomAnchor),
                ])
            }

            orientationManager.updateViews(renderView: renderView, containerView: containerView)
        }
    }
#endif
