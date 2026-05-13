//
//  FullscreenConfiguration.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import UIKit

    /// 全屏展示模式。
    public enum FullscreenMode: Equatable, Sendable {
        /// 根据环境自动选择全屏模式。
        case automatic

        /// 横屏全屏。
        case landscape

        /// 竖屏全屏。
        case portrait
    }

    /// 竖屏全屏内容布局模式。
    public enum PortraitFullscreenMode: Equatable, Sendable {
        /// 拉伸填满竖屏全屏区域。
        case scaleToFill

        /// 等比例完整显示在竖屏全屏区域。
        case scaleAspectFit
    }

    /// 全屏行为配置。
    public struct FullscreenConfiguration: Equatable, Sendable {
        /// 默认全屏展示模式。
        public var mode: FullscreenMode

        /// 竖屏全屏内容布局模式。
        public var portraitMode: PortraitFullscreenMode

        /// 全屏状态栏样式。
        public var statusBarStyle: UIStatusBarStyle

        /// 是否启用设备方向触发全屏切换。
        public var isDeviceOrientationFullscreenEnabled: Bool

        /// 创建全屏行为配置。
        public init(
            mode: FullscreenMode = .automatic,
            portraitMode: PortraitFullscreenMode = .scaleAspectFit,
            statusBarStyle: UIStatusBarStyle = .lightContent,
            isDeviceOrientationFullscreenEnabled: Bool = true
        ) {
            self.mode = mode
            self.portraitMode = portraitMode
            self.statusBarStyle = statusBarStyle
            self.isDeviceOrientationFullscreenEnabled = isDeviceOrientationFullscreenEnabled
        }
    }
#endif
