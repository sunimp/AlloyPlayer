//
//  FloatingPlaybackCoordinator.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/12.
//

#if canImport(UIKit)
    import AlloyCore
    import UIKit

    /// 浮动播放窗口协调器。
    @MainActor
    public final class FloatingPlaybackCoordinator {
        public private(set) weak var floatingView: FloatingView?

        public var isVisible: Bool {
            floatingView?.superview != nil
        }

        private weak var player: Player?
        private weak var parentView: UIView?
        private let frameProvider: @MainActor (UIView) -> CGRect
        private var renderSurfaceConstraints: [NSLayoutConstraint] = []
        private var retainedFloatingView: FloatingView?

        public init(
            player: Player,
            parentView: UIView,
            frameProvider: (@MainActor (UIView) -> CGRect)? = nil
        ) {
            self.player = player
            self.parentView = parentView
            self.frameProvider = frameProvider ?? Self.defaultFrame(in:)
        }

        public func show() {
            guard let player, let parentView else { return }
            let floatingView = retainedFloatingView ?? makeFloatingView(in: parentView)
            retainedFloatingView = floatingView
            self.floatingView = floatingView

            if floatingView.superview !== parentView {
                parentView.addSubview(floatingView)
            }

            attachRenderSurface(player.engine.renderSurface.view, to: floatingView)
        }

        public func hide() {
            NSLayoutConstraint.deactivate(renderSurfaceConstraints)
            renderSurfaceConstraints.removeAll()
            player?.engine.renderSurface.view.removeFromSuperview()
            retainedFloatingView?.removeFromSuperview()
            retainedFloatingView = nil
            floatingView = nil
        }

        private func makeFloatingView(in parentView: UIView) -> FloatingView {
            let floatingView = FloatingView(frame: frameProvider(parentView))
            floatingView.parentView = parentView
            floatingView.safeInsets = parentView.safeAreaInsets
            return floatingView
        }

        private func attachRenderSurface(_ renderSurfaceView: UIView, to floatingView: FloatingView) {
            NSLayoutConstraint.deactivate(renderSurfaceConstraints)
            renderSurfaceConstraints.removeAll()

            if renderSurfaceView.superview !== floatingView {
                renderSurfaceView.removeFromSuperview()
                floatingView.addSubview(renderSurfaceView)
            }

            renderSurfaceView.translatesAutoresizingMaskIntoConstraints = false
            renderSurfaceConstraints = [
                renderSurfaceView.topAnchor.constraint(equalTo: floatingView.topAnchor),
                renderSurfaceView.leadingAnchor.constraint(equalTo: floatingView.leadingAnchor),
                renderSurfaceView.trailingAnchor.constraint(equalTo: floatingView.trailingAnchor),
                renderSurfaceView.bottomAnchor.constraint(equalTo: floatingView.bottomAnchor),
            ]
            NSLayoutConstraint.activate(renderSurfaceConstraints)
        }

        private static func defaultFrame(in parentView: UIView) -> CGRect {
            CGRect(
                x: parentView.bounds.width - 212,
                y: parentView.bounds.height - 168,
                width: 192,
                height: 108
            )
        }
    }
#endif
