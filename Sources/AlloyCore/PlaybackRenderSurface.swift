//
//  PlaybackRenderSurface.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/12.
//

#if canImport(UIKit)
    import UIKit

    /// 播放渲染承载面
    ///
    /// 面向播放器编排层暴露稳定的视图挂载入口，避免编排逻辑直接绑定具体的
    /// `RenderView` 实现。
    @MainActor
    public protocol PlaybackRenderSurface: AnyObject {
        /// 可挂载到播放器容器中的渲染视图。
        var view: UIView { get }
    }

    /// 基于 `RenderView` 的默认渲染承载面。
    @MainActor
    public final class RenderViewSurface: PlaybackRenderSurface {
        public let renderView: RenderView

        public var view: UIView {
            renderView
        }

        public init(renderView: RenderView) {
            self.renderView = renderView
        }
    }
#endif
