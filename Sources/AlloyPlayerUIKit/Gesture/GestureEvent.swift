//
//  GestureEvent.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import CoreGraphics
    import Foundation

    /// 播放器手势类型。
    public enum GestureType: Equatable, Hashable, Sendable {
        /// 未识别的手势类型。
        case unknown

        /// 单击手势。
        case singleTap

        /// 双击手势。
        case doubleTap

        /// 拖动手势。
        case pan

        /// 捏合手势。
        case pinch

        /// 长按手势。
        case longPress
    }

    /// 拖动手势方向。
    public enum PanDirection: Equatable, Hashable, Sendable {
        /// 未识别的拖动方向。
        case unknown

        /// 垂直拖动。
        case vertical

        /// 水平拖动。
        case horizontal
    }

    /// 拖动手势所在区域。
    public enum PanLocation: Equatable, Hashable, Sendable {
        /// 未识别的拖动区域。
        case unknown

        /// 视图左侧。
        case left

        /// 视图右侧。
        case right
    }

    /// 长按手势阶段。
    public enum LongPressPhase: Equatable, Hashable, Sendable {
        /// 长按开始。
        case began

        /// 长按状态变化。
        case changed

        /// 长按结束。
        case ended
    }

    /// 播放器手势事件。
    public enum GestureEvent: Equatable, Sendable {
        /// 单击事件。
        case singleTap

        /// 双击事件。
        case doubleTap

        /// 拖动开始事件。
        case panBegan(direction: PanDirection, location: PanLocation)

        /// 拖动变化事件。
        case panChanged(direction: PanDirection, location: PanLocation, velocity: CGPoint)

        /// 拖动结束事件。
        case panEnded(direction: PanDirection, location: PanLocation)

        /// 捏合事件。
        case pinch(scale: CGFloat)

        /// 长按事件。
        case longPress(LongPressPhase)
    }
#endif
