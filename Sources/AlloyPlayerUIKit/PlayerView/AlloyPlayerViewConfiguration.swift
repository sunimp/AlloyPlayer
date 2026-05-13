//
//  AlloyPlayerViewConfiguration.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    /// UIKit 播放器视图配置。
    public struct AlloyPlayerViewConfiguration {
        /// 是否自动挂载播放渲染承载面。
        public var attachesRenderSurfaceAutomatically: Bool

        /// 从 window 移除时是否自动暂停播放。
        public var pausesWhenDetachedFromWindow: Bool

        /// 播放停止时是否自动退出全屏。
        public var exitsFullscreenWhenStopped: Bool

        /// 创建 UIKit 播放器视图配置。
        public init(
            attachesRenderSurfaceAutomatically: Bool = true,
            pausesWhenDetachedFromWindow: Bool = true,
            exitsFullscreenWhenStopped: Bool = true
        ) {
            self.attachesRenderSurfaceAutomatically = attachesRenderSurfaceAutomatically
            self.pausesWhenDetachedFromWindow = pausesWhenDetachedFromWindow
            self.exitsFullscreenWhenStopped = exitsFullscreenWhenStopped
        }
    }
#endif
