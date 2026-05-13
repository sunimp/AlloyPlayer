//
//  AlloyPlayerView.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyAVPlayer
    import AlloyCore
    import Combine
    import UIKit

    /// UIKit 播放器视图。
    @MainActor
    public final class AlloyPlayerView: UIView {
        /// 播放器绑定的播放会话。
        public let session: PlaybackSession

        /// 播放器视图配置。
        public var configuration: AlloyPlayerViewConfiguration {
            didSet {
                handlePlaybackStateChange(session.state)
            }
        }

        /// 全屏协调器。
        public var fullscreenCoordinator: FullscreenCoordinating? {
            didSet { bindFullscreenCoordinator() }
        }

        /// 手势控制器。
        public var gestureController: GestureController? {
            didSet { installGestureController() }
        }

        /// 当前控制层视图。
        public var controlOverlay: (UIView & UIKitControlOverlay)? {
            didSet { installControlOverlay() }
        }

        let renderHostView: RenderHostView
        private let binder = PlaybackSessionBinder()
        private let deviceOrientationFullscreenController = DeviceOrientationFullscreenController()
        private var overlayConstraints: [NSLayoutConstraint] = []
        private var fullscreenCancellable: AnyCancellable?
        private var gestureCancellable: AnyCancellable?

        /// 使用既有播放会话创建播放器视图。
        public init(
            session: PlaybackSession,
            configuration: AlloyPlayerViewConfiguration = .init()
        ) {
            self.session = session
            self.configuration = configuration
            renderHostView = RenderHostView()
            gestureController = GestureController()
            super.init(frame: .zero)
            setupViews()
            binder.bind(session: session, playerView: self)
            installGestureController()
            bindDeviceOrientationFullscreenController()
        }

        /// 创建带默认控制层的播放器视图。
        public convenience init(
            source: PlaybackSource? = nil,
            sessionConfiguration: PlaybackSessionConfiguration = .init(),
            engineConfiguration: AVPlaybackEngineConfiguration = .init(),
            configuration: AlloyPlayerViewConfiguration = .init()
        ) {
            self.init(
                source: source,
                sessionConfiguration: sessionConfiguration,
                engineConfiguration: engineConfiguration,
                configuration: configuration,
                controlOverlay: DefaultControlOverlay()
            )
        }

        /// 创建带指定控制层的播放器视图。
        public convenience init(
            source: PlaybackSource? = nil,
            sessionConfiguration: PlaybackSessionConfiguration = .init(),
            engineConfiguration: AVPlaybackEngineConfiguration = .init(),
            configuration: AlloyPlayerViewConfiguration = .init(),
            controlOverlay: (UIView & UIKitControlOverlay)?
        ) {
            let session = PlaybackSession(
                engine: AVPlaybackEngine(configuration: engineConfiguration),
                configuration: sessionConfiguration
            )
            self.init(session: session, configuration: configuration)
            self.controlOverlay = controlOverlay

            if let source {
                load(source)
            }
        }

        /// 不支持从 Interface Builder 或 Storyboard 创建。
        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// 加载播放源。
        public func load(_ source: PlaybackSource) {
            session.load(source)
        }

        /// 开始或恢复播放。
        public func play() {
            session.play()
        }

        /// 暂停播放。
        public func pause() {
            session.pause()
        }

        /// 停止播放。
        public func stop() {
            session.stop()
        }

        override public func didMoveToWindow() {
            super.didMoveToWindow()
            guard window == nil, configuration.pausesWhenDetachedFromWindow else { return }
            session.pause()
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            renderControlOverlay()
        }

        private func setupViews() {
            renderHostView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(renderHostView)
            NSLayoutConstraint.activate([
                renderHostView.topAnchor.constraint(equalTo: topAnchor),
                renderHostView.leadingAnchor.constraint(equalTo: leadingAnchor),
                renderHostView.trailingAnchor.constraint(equalTo: trailingAnchor),
                renderHostView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        private func installControlOverlay() {
            overlayConstraints.removeAll()
            subviews
                .filter { $0 !== renderHostView && $0 is UIKitControlOverlay }
                .forEach { $0.removeFromSuperview() }

            guard let controlOverlay else { return }
            controlOverlay.actionHandler = { [weak self] action in
                self?.handleControlAction(action)
            }
            controlOverlay.translatesAutoresizingMaskIntoConstraints = false
            addSubview(controlOverlay)
            overlayConstraints = [
                controlOverlay.topAnchor.constraint(equalTo: topAnchor),
                controlOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
                controlOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
                controlOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            ]
            NSLayoutConstraint.activate(overlayConstraints)
            renderControlOverlay()
        }

        private func installGestureController() {
            gestureCancellable = nil
            gestureController?.detach()
            guard let gestureController else { return }
            gestureController.shouldReceiveTouch = { [weak self] type, recognizer, touch in
                self?.controlOverlay?.shouldReceiveGesture(type, recognizer: recognizer, touch: touch) ?? true
            }
            gestureCancellable = gestureController.eventPublisher.sink { [weak self] event in
                self?.controlOverlay?.handle(input: .gesture(event))
            }
            gestureController.attach(to: self)
        }

        private func bindFullscreenCoordinator() {
            fullscreenCancellable = nil
            (fullscreenCoordinator as? FullscreenCoordinator)?.setPresentationSourceProvider { [weak self] in
                self
            }
            bindDeviceOrientationFullscreenController()
            guard let fullscreenCoordinator else {
                renderControlOverlay(fullscreenState: .inline)
                return
            }
            renderControlOverlay(fullscreenState: fullscreenCoordinator.state)
            fullscreenCancellable = fullscreenCoordinator.statePublisher.sink { [weak self] state in
                self?.renderControlOverlay(fullscreenState: state)
            }
            handlePlaybackStateChange(session.state)
        }

        func renderControlOverlay(state: PlaybackStateSnapshot? = nil, fullscreenState: FullscreenState? = nil) {
            controlOverlay?.render(context: makeControlContext(state: state, fullscreenState: fullscreenState))
        }

        func handleControlInput(_ input: PlaybackControlInput) {
            controlOverlay?.handle(input: input)
        }

        func handlePlaybackStateChange(_ state: PlaybackStateSnapshot) {
            guard shouldExitFullscreen(for: state.engine.playbackState),
                  configuration.exitsFullscreenWhenStopped,
                  fullscreenCoordinator?.state == .fullscreen
            else { return }
            Task { [weak fullscreenCoordinator] in
                await fullscreenCoordinator?.setFullscreen(false, animated: true)
            }
        }

        private func shouldExitFullscreen(for playbackState: PlaybackState) -> Bool {
            switch playbackState {
            case .ended, .stopped:
                true
            case .idle, .loading, .ready, .playing, .paused, .seeking, .buffering, .failed:
                false
            }
        }

        private func makeControlContext(
            state: PlaybackStateSnapshot? = nil,
            fullscreenState: FullscreenState? = nil
        ) -> PlaybackControlContext {
            let resolvedState = state ?? session.state
            let resolvedFullscreenState = fullscreenState ?? fullscreenCoordinator?.state ?? .inline
            let resolvedFullscreenMode = fullscreenCoordinator?.fullscreenMode ?? .automatic
            return PlaybackControlContext(
                state: resolvedState,
                fullscreenState: resolvedFullscreenState,
                fullscreenMode: resolvedFullscreenMode,
                layout: controlLayout(fullscreenState: resolvedFullscreenState, fullscreenMode: resolvedFullscreenMode)
            )
        }

        private func controlLayout(
            fullscreenState: FullscreenState,
            fullscreenMode: FullscreenMode
        ) -> PlaybackControlLayout {
            guard fullscreenState == .fullscreen else { return .inline }
            switch fullscreenMode {
            case .portrait:
                return .fullscreenPortrait
            case .landscape:
                return isLandscapeGeometry ? .fullscreenLandscape : .fullscreenPortrait
            case .automatic:
                return isLandscapeGeometry ? .fullscreenLandscape : .fullscreenPortrait
            }
        }

        private var isLandscapeGeometry: Bool {
            if let interfaceOrientation = window?.windowScene?.interfaceOrientation,
               interfaceOrientation != .unknown
            {
                return interfaceOrientation.isLandscape
            }
            return bounds.width > bounds.height
        }

        private func handleControlAction(_ action: PlaybackControlAction) {
            switch action {
            case .play:
                session.play()
            case .pause:
                session.pause()
            case .replay:
                Task {
                    _ = await session.seek(to: 0)
                    session.play()
                }
            case let .seek(time):
                Task { _ = await session.seek(to: time) }
            case let .setRate(rate):
                session.send(.setRate(rate))
            case let .setMuted(isMuted):
                session.send(.setMuted(isMuted))
            case let .setVolume(volume):
                session.send(.setVolume(volume))
            case let .setScalingMode(scalingMode):
                session.send(.setScalingMode(scalingMode))
            case .toggleFullscreen:
                Task {
                    await fullscreenCoordinator?.toggle(animated: true)
                }
            }
        }

        private func bindDeviceOrientationFullscreenController() {
            deviceOrientationFullscreenController.bind(
                session: session,
                fullscreenCoordinator: fullscreenCoordinator
            )
        }
    }
#endif
