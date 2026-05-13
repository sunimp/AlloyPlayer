//
//  AlloyPlayerRenderView.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import Combine
    import UIKit

    /// 独立的播放器渲染宿主。
    @MainActor
    public final class AlloyPlayerRenderView: UIView, RenderSurfaceHosting {
        public private(set) var session: PlaybackSession?
        public private(set) var isRenderSurfaceActive = false

        private weak var hostedLayer: CALayer?
        private var cancellable: AnyCancellable?

        public init(session: PlaybackSession? = nil, frame: CGRect = .zero) {
            self.session = session
            super.init(frame: frame)
            bindSession()
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public func bind(session: PlaybackSession?) {
            self.session = session
            bindSession()
            if isRenderSurfaceActive {
                attach(surface: session?.engine.renderSurface)
            }
        }

        public func activateRenderSurface() {
            isRenderSurfaceActive = true
            attach(surface: session?.engine.renderSurface)
        }

        public func deactivateRenderSurface() {
            isRenderSurfaceActive = false
            detachSurface()
        }

        public func attach(surface: PlaybackRenderSurface?) {
            performWithoutImplicitLayerAnimations {
                detachSurface()
                guard let layerBackedSurface = surface as? LayerBackedRenderSurface else { return }
                hostedLayer = layerBackedSurface.layer
                layerBackedSurface.layer.frame = bounds
                layer.insertSublayer(layerBackedSurface.layer, at: 0)
            }
        }

        public func detachSurface() {
            performWithoutImplicitLayerAnimations {
                hostedLayer?.removeFromSuperlayer()
                hostedLayer = nil
            }
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            performWithoutImplicitLayerAnimations {
                hostedLayer?.frame = bounds
            }
        }

        private func bindSession() {
            cancellable = nil
            guard let session else { return }
            cancellable = session.statePublisher.sink { [weak self, weak session] _ in
                guard let self, self.isRenderSurfaceActive else { return }
                self.attach(surface: session?.engine.renderSurface)
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
