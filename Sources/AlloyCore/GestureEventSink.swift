//
//  GestureEventSink.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/12.
//

#if canImport(UIKit)
    import UIKit

    /// 手势事件接收者。
    @MainActor
    public protocol GestureEventSink: AnyObject {
        func gestureTriggerCondition(
            _ gesture: GestureManager,
            type: GestureType,
            recognizer: UIGestureRecognizer,
            touch: UITouch
        ) -> Bool

        func gestureSingleTapped(_ gesture: GestureManager)
        func gestureDoubleTapped(_ gesture: GestureManager)
        func gestureBeganPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation)
        func gestureChangedPan(
            _ gesture: GestureManager,
            direction: PanDirection,
            location: PanLocation,
            velocity: CGPoint
        )
        func gestureEndedPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation)
        func gesturePinched(_ gesture: GestureManager, scale: Float)
        func longPressed(_ gesture: GestureManager, state: LongPressPhase)
    }

    public extension GestureEventSink {
        func gestureTriggerCondition(_: GestureManager, type _: GestureType, recognizer _: UIGestureRecognizer, touch _: UITouch) -> Bool {
            true
        }

        func gestureSingleTapped(_: GestureManager) {}
        func gestureDoubleTapped(_: GestureManager) {}
        func gestureBeganPan(_: GestureManager, direction _: PanDirection, location _: PanLocation) {}
        func gestureChangedPan(_: GestureManager, direction _: PanDirection, location _: PanLocation, velocity _: CGPoint) {}
        func gestureEndedPan(_: GestureManager, direction _: PanDirection, location _: PanLocation) {}
        func gesturePinched(_: GestureManager, scale _: Float) {}
        func longPressed(_: GestureManager, state _: LongPressPhase) {}
    }
#endif
