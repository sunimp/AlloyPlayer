//
//  AlloyPlayerControlView.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import Combine
    import UIKit

    /// 独立的播放器控制层宿主。
    @MainActor
    public final class AlloyPlayerControlView: UIView {
        public private(set) var session: PlaybackSession

        public var fullscreenCoordinator: FullscreenCoordinating? {
            didSet { bindFullscreenCoordinator() }
        }

        public var gestureController: GestureController? {
            didSet { installGestureController() }
        }

        public var controlOverlay: (UIView & UIKitControlOverlay)? {
            didSet { installControlOverlay() }
        }

        private var overlayConstraints: [NSLayoutConstraint] = []
        private let deviceOrientationFullscreenController = DeviceOrientationFullscreenController()
        private var sessionCancellables = Set<AnyCancellable>()
        private var fullscreenCancellable: AnyCancellable?
        private var gestureCancellable: AnyCancellable?

        public init(
            session: PlaybackSession,
            controlOverlay: (UIView & UIKitControlOverlay)? = nil,
            gestureController: GestureController?
        ) {
            self.session = session
            self.controlOverlay = controlOverlay
            self.gestureController = gestureController
            super.init(frame: .zero)
            bindSession()
            installControlOverlay()
            installGestureController()
            bindDeviceOrientationFullscreenController()
        }

        public convenience init(
            session: PlaybackSession,
            controlOverlay: (UIView & UIKitControlOverlay)? = nil
        ) {
            self.init(
                session: session,
                controlOverlay: controlOverlay,
                gestureController: GestureController()
            )
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public func bind(session: PlaybackSession) {
            self.session = session
            bindSession()
            bindDeviceOrientationFullscreenController()
            controlOverlay?.render(state: session.state)
        }

        public func send(_ action: PlaybackControlAction) {
            handleControlAction(action)
        }

        private func bindSession() {
            sessionCancellables.removeAll()
            session.statePublisher
                .sink { [weak self] state in
                    self?.controlOverlay?.render(state: state)
                }
                .store(in: &sessionCancellables)

            session.eventPublisher
                .sink { [weak self] event in
                    self?.controlOverlay?.handle(event: event)
                }
                .store(in: &sessionCancellables)
        }

        private func installControlOverlay() {
            NSLayoutConstraint.deactivate(overlayConstraints)
            overlayConstraints.removeAll()
            subviews
                .filter { $0 is UIKitControlOverlay }
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
            (fullscreenCoordinator as? FullscreenCoordinator)?.setPresentationSourceProvider { [weak self] in
                self?.superview ?? self
            }
            bindDeviceOrientationFullscreenController()
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

        private func bindDeviceOrientationFullscreenController() {
            deviceOrientationFullscreenController.bind(
                session: session,
                fullscreenCoordinator: fullscreenCoordinator
            )
        }
    }
#endif
