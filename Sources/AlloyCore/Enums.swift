//
//  Enums.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Foundation

// MARK: - 播放状态

/// 播放状态枚举
public enum PlaybackState: Int, Sendable {
    /// 未知
    case unknown
    /// 播放中
    case playing
    /// 已暂停
    case paused
    /// 播放失败
    case failed
    /// 已停止
    case stopped
}

// MARK: - 加载状态

/// 加载状态（支持组合）
public struct LoadState: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let unknown = LoadState([])
    public static let prepare = LoadState(rawValue: 1 << 0)
    public static let playable = LoadState(rawValue: 1 << 1)
    public static let playthroughOK = LoadState(rawValue: 1 << 2)
    public static let stalled = LoadState(rawValue: 1 << 3)
}

// MARK: - 缩放模式

/// 视频缩放模式
public enum ScalingMode: Int, Sendable {
    /// 无缩放
    case none
    /// 等比缩放适配（留黑边）
    case aspectFit
    /// 等比缩放填充（裁剪）
    case aspectFill
    /// 拉伸填充
    case fill
}

// MARK: - 全屏模式

/// 全屏模式
public enum FullScreenMode: Int, Sendable {
    /// 根据视频宽高比自动选择
    case automatic
    /// 强制横屏全屏
    case landscape
    /// 竖屏全屏（上下展开）
    case portrait
}

/// 竖屏全屏模式
public enum PortraitFullScreenMode: Int, Sendable {
    /// 拉伸填满
    case scaleToFill
    /// 等比适配
    case scaleAspectFit
}

// MARK: - 手势相关

/// 手势类型
public enum GestureType: Int, Sendable {
    case unknown
    case singleTap
    case doubleTap
    case pan
    case pinch
}

/// 禁用手势类型（支持组合）
public struct DisableGestureTypes: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let singleTap = DisableGestureTypes(rawValue: 1 << 0)
    public static let doubleTap = DisableGestureTypes(rawValue: 1 << 1)
    public static let pan = DisableGestureTypes(rawValue: 1 << 2)
    public static let pinch = DisableGestureTypes(rawValue: 1 << 3)
    public static let longPress = DisableGestureTypes(rawValue: 1 << 4)
    public static let all: DisableGestureTypes = [.singleTap, .doubleTap, .pan, .pinch, .longPress]
}

/// 滑动方向
public enum PanDirection: Int, Sendable {
    case unknown
    case vertical
    case horizontal
}

/// 滑动位置（屏幕左半/右半）
public enum PanLocation: Int, Sendable {
    case unknown
    case left
    case right
}

/// 滑动移动方向
public enum PanMovingDirection: Int, Sendable {
    case unknown
    case top
    case left
    case bottom
    case right
}

/// 禁用滑动方向（支持组合）
public struct DisablePanMovingDirection: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let vertical = DisablePanMovingDirection(rawValue: 1 << 0)
    public static let horizontal = DisablePanMovingDirection(rawValue: 1 << 1)
    public static let all: DisablePanMovingDirection = [.vertical, .horizontal]
}

/// 长按手势阶段
public enum LongPressPhase: Int, Sendable {
    case began
    case changed
    case ended
}

// MARK: - 屏幕方向

/// 支持的屏幕方向（支持组合）
public struct InterfaceOrientationMask: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let portrait = InterfaceOrientationMask(rawValue: 1 << 0)
    public static let landscapeLeft = InterfaceOrientationMask(rawValue: 1 << 1)
    public static let landscapeRight = InterfaceOrientationMask(rawValue: 1 << 2)
    public static let portraitUpsideDown = InterfaceOrientationMask(rawValue: 1 << 3)
    public static let landscape: InterfaceOrientationMask = [.landscapeLeft, .landscapeRight]
    public static let all: InterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
    public static let allButUpsideDown: InterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight]
}

/// 禁用竖屏全屏手势类型
public struct DisablePortraitGestureTypes: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let tap = DisablePortraitGestureTypes(rawValue: 1 << 0)
    public static let pan = DisablePortraitGestureTypes(rawValue: 1 << 1)
    public static let all: DisablePortraitGestureTypes = [.tap, .pan]
}

// MARK: - 滚动视图相关

/// 滚动方向
public enum ScrollDirection: Int, Sendable {
    case none
    case up
    case down
    case left
    case right
}

/// 滚动视图方向
public enum ScrollViewDirection: Int, Sendable {
    case vertical
    case horizontal
}

/// 播放器挂载模式
public enum AttachmentMode: Int, Sendable {
    /// 挂载到普通视图
    case view
    /// 挂载到列表 Cell
    case cell
}

/// 滚动锚点位置
public enum ScrollAnchor: Int, Sendable {
    case none
    case top
    case centeredVertically
    case bottom
    case left
    case centeredHorizontally
    case right
}

// MARK: - 网络状态

/// 网络可达性状态
public enum ReachabilityStatus: Int, Sendable {
    case unknown = -1
    case notReachable = 0
    case wifi = 1
    case cellular2G = 2
    case cellular3G = 3
    case cellular4G = 4
    case cellular5G = 5
}

// MARK: - 其他

/// 前后台状态
public enum BackgroundState: Int, Sendable {
    case foreground
    case background
}

/// 加载动画类型
public enum LoadingType: Int, Sendable {
    /// 保持显示
    case keep
    /// 淡出消失
    case fadeOut
}
