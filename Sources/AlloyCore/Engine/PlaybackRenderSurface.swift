//
//  PlaybackRenderSurface.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import CoreGraphics

/// 播放渲染承载面。
public protocol PlaybackRenderSurface: AnyObject {
    /// 当前视频展示尺寸。
    var presentationSize: CGSize { get }
}
