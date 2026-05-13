//
//  GestureController.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import Combine
    import UIKit

    /// UIKit 播放手势控制器。
    @MainActor
    public final class GestureController: NSObject {
        public var configuration: GestureConfiguration
        public var shouldReceiveTouch: ((GestureType, UIGestureRecognizer, UITouch) -> Bool)?

        public var eventPublisher: AnyPublisher<GestureEvent, Never> {
            eventSubject.eraseToAnyPublisher()
        }

        private let eventSubject = PassthroughSubject<GestureEvent, Never>()
        private weak var attachedView: UIView?
        private var panDirection: PanDirection = .unknown
        private var panLocation: PanLocation = .unknown

        private lazy var singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        private lazy var doubleTap: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            recognizer.numberOfTapsRequired = 2
            return recognizer
        }()

        private lazy var pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        private lazy var pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        private lazy var longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))

        public init(configuration: GestureConfiguration = .init()) {
            self.configuration = configuration
            super.init()
            [singleTap, doubleTap, pan, pinch, longPress].forEach { $0.delegate = self }
            singleTap.require(toFail: doubleTap)
        }

        public func attach(to view: UIView) {
            detach()
            attachedView = view
            view.isUserInteractionEnabled = true
            [singleTap, doubleTap, pan, pinch, longPress].forEach(view.addGestureRecognizer)
        }

        public func detach() {
            guard let attachedView else { return }
            [singleTap, doubleTap, pan, pinch, longPress].forEach(attachedView.removeGestureRecognizer)
            self.attachedView = nil
        }

        @objc private func handleSingleTap(_: UITapGestureRecognizer) {
            eventSubject.send(.singleTap)
        }

        @objc private func handleDoubleTap(_: UITapGestureRecognizer) {
            eventSubject.send(.doubleTap)
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let velocity = recognizer.velocity(in: view)
            let location = recognizer.location(in: view)

            switch recognizer.state {
            case .began:
                panDirection = abs(velocity.x) > abs(velocity.y) ? .horizontal : .vertical
                panLocation = location.x > view.bounds.midX ? .right : .left
                eventSubject.send(.panBegan(direction: panDirection, location: panLocation))
            case .changed:
                eventSubject.send(.panChanged(direction: panDirection, location: panLocation, velocity: velocity))
            case .ended, .cancelled, .failed:
                eventSubject.send(.panEnded(direction: panDirection, location: panLocation))
                panDirection = .unknown
                panLocation = .unknown
            default:
                break
            }
        }

        @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            eventSubject.send(.pinch(scale: recognizer.scale))
        }

        @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                eventSubject.send(.longPress(.began))
            case .changed:
                eventSubject.send(.longPress(.changed))
            case .ended, .cancelled, .failed:
                eventSubject.send(.longPress(.ended))
            default:
                break
            }
        }

        private func type(for recognizer: UIGestureRecognizer) -> GestureType {
            switch recognizer {
            case singleTap:
                .singleTap
            case doubleTap:
                .doubleTap
            case pan:
                .pan
            case pinch:
                .pinch
            case longPress:
                .longPress
            default:
                .unknown
            }
        }
    }

    extension GestureController: UIGestureRecognizerDelegate {
        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            let gestureType = type(for: gestureRecognizer)
            guard !configuration.disabledTypes.contains(gestureType) else { return false }
            return shouldReceiveTouch?(gestureType, gestureRecognizer, touch) ?? true
        }

        public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard gestureRecognizer === pan, let view = gestureRecognizer.view else { return true }
            let velocity = pan.velocity(in: view)
            let direction: PanDirection = abs(velocity.x) > abs(velocity.y) ? .horizontal : .vertical
            return !configuration.disabledPanDirections.contains(direction)
        }
    }
#endif
