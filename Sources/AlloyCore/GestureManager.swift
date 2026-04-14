//
//  GestureManager.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import Combine
    import UIKit

    /// 手势管理器
    ///
    /// 管理播放器视图上的单击、双击、滑动、捏合、长按手势，
    /// 通过 Combine Publisher 分发手势事件。
    @MainActor
    public final class GestureManager: NSObject {
        // MARK: - 手势识别器

        public private(set) lazy var singleTap: UITapGestureRecognizer = {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
            tap.numberOfTapsRequired = 1
            tap.numberOfTouchesRequired = 1
            tap.delaysTouchesBegan = true
            tap.delegate = self
            return tap
        }()

        public private(set) lazy var doubleTap: UITapGestureRecognizer = {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            tap.numberOfTapsRequired = 2
            tap.numberOfTouchesRequired = 1
            tap.delaysTouchesBegan = true
            tap.delegate = self
            return tap
        }()

        public private(set) lazy var pan: UIPanGestureRecognizer = {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.maximumNumberOfTouches = 1
            pan.cancelsTouchesInView = true
            pan.delaysTouchesBegan = true
            pan.delegate = self
            return pan
        }()

        public private(set) lazy var pinch: UIPinchGestureRecognizer = {
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinch.delaysTouchesBegan = true
            pinch.delegate = self
            return pinch
        }()

        public private(set) lazy var longPress: UILongPressGestureRecognizer = {
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            lp.delaysTouchesBegan = true
            lp.delegate = self
            return lp
        }()

        // MARK: - 状态

        public private(set) var panDirection: PanDirection = .unknown
        public private(set) var panLocation: PanLocation = .unknown
        public private(set) var panMovingDirection: PanMovingDirection = .unknown

        // MARK: - 配置

        /// 禁用的手势类型
        public var disabledGestureTypes: DisableGestureTypes = []

        /// 禁用的滑动方向
        public var disabledPanMovingDirection: DisablePanMovingDirection = []

        /// 手势触发条件过滤
        public var triggerCondition: ((_ type: GestureType, _ recognizer: UIGestureRecognizer, _ touch: UITouch) -> Bool)?

        // MARK: - Combine Subjects

        private let _singleTap = PassthroughSubject<Void, Never>()
        private let _doubleTap = PassthroughSubject<Void, Never>()
        private let _panBegan = PassthroughSubject<(direction: PanDirection, location: PanLocation), Never>()
        private let _panChanged = PassthroughSubject<(direction: PanDirection, location: PanLocation, velocity: CGPoint), Never>()
        private let _panEnded = PassthroughSubject<(direction: PanDirection, location: PanLocation), Never>()
        private let _pinch = PassthroughSubject<Float, Never>()
        private let _longPress = PassthroughSubject<LongPressPhase, Never>()

        // MARK: - Combine 事件流

        public var singleTapPublisher: AnyPublisher<Void, Never> {
            _singleTap.eraseToAnyPublisher()
        }

        public var doubleTapPublisher: AnyPublisher<Void, Never> {
            _doubleTap.eraseToAnyPublisher()
        }

        public var panBeganPublisher: AnyPublisher<(direction: PanDirection, location: PanLocation), Never> {
            _panBegan.eraseToAnyPublisher()
        }

        public var panChangedPublisher: AnyPublisher<(direction: PanDirection, location: PanLocation, velocity: CGPoint), Never> {
            _panChanged.eraseToAnyPublisher()
        }

        public var panEndedPublisher: AnyPublisher<(direction: PanDirection, location: PanLocation), Never> {
            _panEnded.eraseToAnyPublisher()
        }

        public var pinchPublisher: AnyPublisher<Float, Never> {
            _pinch.eraseToAnyPublisher()
        }

        public var longPressPublisher: AnyPublisher<LongPressPhase, Never> {
            _longPress.eraseToAnyPublisher()
        }

        // MARK: - 方法

        /// 将手势绑定到指定视图
        public func attach(to view: UIView) {
            view.isUserInteractionEnabled = true
            singleTap.require(toFail: doubleTap)
            pan.require(toFail: singleTap)
            view.addGestureRecognizer(singleTap)
            view.addGestureRecognizer(doubleTap)
            view.addGestureRecognizer(pan)
            view.addGestureRecognizer(pinch)
            view.addGestureRecognizer(longPress)
        }

        /// 从指定视图移除手势
        public func detach(from view: UIView) {
            view.removeGestureRecognizer(singleTap)
            view.removeGestureRecognizer(doubleTap)
            view.removeGestureRecognizer(pan)
            view.removeGestureRecognizer(pinch)
            view.removeGestureRecognizer(longPress)
        }

        // MARK: - 手势处理

        @objc private func handleSingleTap(_: UITapGestureRecognizer) {
            _singleTap.send()
        }

        @objc private func handleDoubleTap(_: UITapGestureRecognizer) {
            _doubleTap.send()
        }

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            let velocity = gesture.velocity(in: view)
            let location = gesture.location(in: view)

            switch gesture.state {
            case .began:
                // 判断滑动方向：比较水平与垂直速度
                panDirection = abs(velocity.x) > abs(velocity.y) ? .horizontal : .vertical
                // 判断滑动位置：屏幕左半或右半
                panLocation = location.x > view.bounds.width / 2 ? .right : .left
                _panBegan.send((direction: panDirection, location: panLocation))

            case .changed:
                // 更新移动方向
                switch panDirection {
                case .horizontal:
                    panMovingDirection = velocity.x > 0 ? .right : .left
                case .vertical:
                    panMovingDirection = velocity.y > 0 ? .bottom : .top
                default:
                    break
                }
                _panChanged.send((direction: panDirection, location: panLocation, velocity: velocity))

            case .ended, .cancelled, .failed:
                _panEnded.send((direction: panDirection, location: panLocation))
                panDirection = .unknown
                panLocation = .unknown
                panMovingDirection = .unknown

            default:
                break
            }
        }

        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .ended {
                _pinch.send(Float(gesture.scale))
            }
        }

        @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                _longPress.send(.began)
            case .changed:
                _longPress.send(.changed)
            case .ended, .cancelled, .failed:
                _longPress.send(.ended)
            default:
                break
            }
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    extension GestureManager: UIGestureRecognizerDelegate {
        public func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            let type = gestureType(for: gestureRecognizer)

            // 检查禁用类型
            switch type {
            case .singleTap where disabledGestureTypes.contains(.singleTap): return false
            case .doubleTap where disabledGestureTypes.contains(.doubleTap): return false
            case .pan where disabledGestureTypes.contains(.pan): return false
            case .pinch where disabledGestureTypes.contains(.pinch): return false
            default: break
            }

            // 长按检查
            if gestureRecognizer === longPress, disabledGestureTypes.contains(.longPress) {
                return false
            }

            // 外部条件过滤
            if let condition = triggerCondition {
                return condition(type, gestureRecognizer, touch)
            }

            return true
        }

        public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer === pan, let view = gestureRecognizer.view {
                let velocity = pan.velocity(in: view)
                if abs(velocity.x) > abs(velocity.y) {
                    // 水平滑动
                    if disabledPanMovingDirection.contains(.horizontal) { return false }
                } else {
                    // 垂直滑动
                    if disabledPanMovingDirection.contains(.vertical) { return false }
                }
            }
            return true
        }

        public func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
        ) -> Bool {
            // 捏合和长按手势不与其他手势同时识别
            false
        }

        // MARK: - 辅助方法

        private func gestureType(for recognizer: UIGestureRecognizer) -> GestureType {
            switch recognizer {
            case singleTap: return .singleTap
            case doubleTap: return .doubleTap
            case pan: return .pan
            case pinch: return .pinch
            default: return .unknown
            }
        }
    }
#endif
