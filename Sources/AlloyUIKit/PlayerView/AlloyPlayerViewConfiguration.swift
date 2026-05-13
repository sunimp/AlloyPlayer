//
//  AlloyPlayerViewConfiguration.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    /// UIKit 播放器视图配置。
    public struct AlloyPlayerViewConfiguration {
        public var attachesRenderSurfaceAutomatically: Bool
        public var pausesWhenDetachedFromWindow: Bool
        public var exitsFullscreenWhenStopped: Bool

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
