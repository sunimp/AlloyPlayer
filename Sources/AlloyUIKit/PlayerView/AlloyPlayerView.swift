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
        public let renderHostView: RenderHostView
        public var configuration: AlloyPlayerViewConfiguration
        public var fullscreenCoordinator: FullscreenCoordinating? {
            didSet { bindFullscreenCoordinator() }
        }

        public var gestureController: GestureController? {
            didSet { installGestureController() }
        }

        public var controlOverlay: (UIView & UIKitControlOverlay)? {
            didSet { installControlOverlay() }
        }

        private let binder = PlaybackSessionBinder()
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
            controlOverlay.render(state: session.state)
            controlOverlay.render(fullscreenState: fullscreenCoordinator?.state ?? .inline)
        }

        private func installGestureController() {
            gestureCancellable = nil
            gestureController?.detach()
            guard let gestureController else { return }
            gestureController.shouldReceiveTouch = { [weak self] type, recognizer, touch in
                self?.controlOverlay?.shouldReceiveGesture(type, recognizer: recognizer, touch: touch) ?? true
            }
            gestureCancellable = gestureController.eventPublisher.sink { [weak self] event in
                self?.controlOverlay?.handle(gesture: event)
            }
            gestureController.attach(to: self)
        }

        private func bindFullscreenCoordinator() {
            fullscreenCancellable = nil
            guard let fullscreenCoordinator else {
                controlOverlay?.render(fullscreenState: .inline)
                return
            }
            controlOverlay?.render(fullscreenState: fullscreenCoordinator.state)
            fullscreenCancellable = fullscreenCoordinator.statePublisher.sink { [weak self] state in
                self?.controlOverlay?.render(fullscreenState: state)
            }
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
    }
#endif
