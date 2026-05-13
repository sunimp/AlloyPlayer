//
//  PlaybackRenderSurface.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import CoreGraphics

/// 播放渲染承载面。
public protocol PlaybackRenderSurface: AnyObject {
    var presentationSize: CGSize { get }
}
