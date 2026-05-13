//
//  AlloyPlayerRenderView.swift
//  AlloyPlayerUIKit
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
        /// 当前绑定的播放会话。
        public private(set) var session: PlaybackSession?

        /// 渲染承载面是否处于激活状态。
        public private(set) var isRenderSurfaceActive = false

        private weak var hostedLayer: CALayer?
        private var cancellable: AnyCancellable?

        /// 创建播放器渲染宿主。
        public init(session: PlaybackSession? = nil, frame: CGRect = .zero) {
            self.session = session
            super.init(frame: frame)
            bindSession()
        }

        /// 不支持从 Interface Builder 或 Storyboard 创建。
        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// 重新绑定播放会话。
        public func bind(session: PlaybackSession?) {
            self.session = session
            bindSession()
            if isRenderSurfaceActive {
                attach(surface: session?.engine.renderSurface)
            }
        }

        /// 激活并挂载当前播放会话的渲染承载面。
        public func activateRenderSurface() {
            isRenderSurfaceActive = true
            attach(surface: session?.engine.renderSurface)
        }

        /// 停用并移除渲染承载面。
        public func deactivateRenderSurface() {
            isRenderSurfaceActive = false
            detachSurface()
        }

        /// 挂载指定渲染承载面。
        public func attach(surface: PlaybackRenderSurface?) {
            performWithoutImplicitLayerAnimations {
                detachSurface()
                guard let layerBackedSurface = surface as? LayerBackedRenderSurface else { return }
                hostedLayer = layerBackedSurface.layer
                layerBackedSurface.layer.frame = bounds
                layer.insertSublayer(layerBackedSurface.layer, at: 0)
            }
        }

        /// 移除当前渲染承载面。
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
