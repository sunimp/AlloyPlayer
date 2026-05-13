//
//  RenderSurfaceHosting.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore

    /// 渲染承载面宿主。
    @MainActor
    public protocol RenderSurfaceHosting: AnyObject {
        func attach(surface: PlaybackRenderSurface?)
        func detachSurface()
    }
#endif
