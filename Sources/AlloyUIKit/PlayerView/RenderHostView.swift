//
//  RenderHostView.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import UIKit

    /// 播放渲染宿主视图。
    @MainActor
    final class RenderHostView: UIView, RenderSurfaceHosting {
        private weak var hostedLayer: CALayer?

        func attach(surface: PlaybackRenderSurface?) {
            detachSurface()
            guard let layerBackedSurface = surface as? LayerBackedRenderSurface else { return }
            hostedLayer = layerBackedSurface.layer
            layer.insertSublayer(layerBackedSurface.layer, at: 0)
            setNeedsLayout()
        }

        func detachSurface() {
            hostedLayer?.removeFromSuperlayer()
            hostedLayer = nil
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            hostedLayer?.frame = bounds
        }
    }
#endif
