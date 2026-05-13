//
//  AlloyPlayerView.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import Combine
    import UIKit

    /// UIKit 播放器视图。
    @MainActor
    public final class AlloyPlayerView: UIView {
        public let session: PlaybackSession
        public var configuration: AlloyPlayerViewConfiguration {
            didSet {
                handlePlaybackStateChange(session.state)
            }
        }

        public var fullscreenCoordinator: FullscreenCoordinating? {
            didSet { bindFullscreenCoordinator() }
        }

        public var gestureController: GestureController? {
            didSet { installGestureController() }
        }

        public var controlOverlay: (UIView & UIKitControlOverlay)? {
            didSet { installControlOverlay() }
        }

        let renderHostView: RenderHostView
        private let binder = PlaybackSessionBinder()
        private let deviceOrientationFullscreenController = DeviceOrientationFullscreenController()
        private var overlayConstraints: [NSLayoutConstraint] = []
        private var fullscreenCancellable: AnyCancellable?
        private var gestureCancellable: AnyCancellable?

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

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public func load(_ source: PlaybackSource) {
            session.load(source)
        }

        public func play() {
            session.play()
        }

        public func pause() {
            session.pause()
        }

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
