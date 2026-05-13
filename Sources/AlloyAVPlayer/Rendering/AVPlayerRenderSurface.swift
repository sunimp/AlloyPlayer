//
//  AVPlayerRenderSurface.swift
//  AlloyAVPlayer
//
//  Created by Sun on 2026/5/13.
//

import AlloyCore
import AVFoundation
import CoreGraphics
import QuartzCore

/// AVPlayerLayer 渲染承载面。
public final class AVPlayerRenderSurface: LayerBackedRenderSurface {
    public let playerLayer: AVPlayerLayer
    public var presentationSize: CGSize
    public var layer: CALayer {
        playerLayer
    }

    init(playerLayer: AVPlayerLayer, presentationSize: CGSize = .zero) {
        self.playerLayer = playerLayer
        self.presentationSize = presentationSize
    }
}
