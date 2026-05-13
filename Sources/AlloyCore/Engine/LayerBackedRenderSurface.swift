//
//  LayerBackedRenderSurface.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import QuartzCore

/// 基于 CALayer 的播放渲染承载面。
public protocol LayerBackedRenderSurface: PlaybackRenderSurface {
    /// 用于展示视频内容的 Core Animation 图层。
    var layer: CALayer { get }
}
