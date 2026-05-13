//
//  RenderHostView.swift
//  AlloyPlayerUIKit
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
            performWithoutImplicitLayerAnimations {
                detachSurface()
                guard let layerBackedSurface = surface as? LayerBackedRenderSurface else { return }
                hostedLayer = layerBackedSurface.layer
                layerBackedSurface.layer.frame = bounds
                layer.insertSublayer(layerBackedSurface.layer, at: 0)
            }
        }

        func detachSurface() {
            performWithoutImplicitLayerAnimations {
                hostedLayer?.removeFromSuperlayer()
                hostedLayer = nil
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            performWithoutImplicitLayerAnimations {
                hostedLayer?.frame = bounds
            }
        }

        private func performWithoutImplicitLayerAnimations(_ updates: () -> Void) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            updates()
            CATransaction.commit()
        }
    }
#endif
