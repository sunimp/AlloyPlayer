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
final class AVPlayerRenderSurface: LayerBackedRenderSurface {
    let playerLayer: AVPlayerLayer
    var presentationSize: CGSize
    var layer: CALayer {
        playerLayer
    }

    init(playerLayer: AVPlayerLayer, presentationSize: CGSize = .zero) {
        self.playerLayer = playerLayer
        self.presentationSize = presentationSize
    }
}
