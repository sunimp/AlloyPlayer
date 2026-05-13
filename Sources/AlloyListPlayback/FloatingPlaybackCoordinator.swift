//
//  FloatingPlaybackCoordinator.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import AlloyUIKit
    import UIKit

    @MainActor
    public final class FloatingPlaybackCoordinator {
        public let session: PlaybackSession
        public let renderView: AlloyUIKit.AlloyPlayerRenderView
        public private(set) var isVisible = false

        private var floatingView: FloatingPlaybackView?
        private let floatingOverlay = FloatingPlaybackOverlay()
        private lazy var controlView = AlloyUIKit.AlloyPlayerControlView(
            session: session,
            controlOverlay: floatingOverlay,
            gestureController: nil
        )
        private weak var legacyPlayerView: AlloyUIKit.AlloyPlayerView?
        private var controlViewConstraints: [NSLayoutConstraint] = []
        private var closeHandler: (() -> Void)?

        public init(
            session: PlaybackSession,
            renderView: AlloyUIKit.AlloyPlayerRenderView
        ) {
            self.session = session
            self.renderView = renderView
        }

        public convenience init(playerView: AlloyUIKit.AlloyPlayerView) {
            self.init(
                session: playerView.session,
                renderView: AlloyUIKit.AlloyPlayerRenderView(session: playerView.session)
            )
            legacyPlayerView = playerView
            playerView.configuration.attachesRenderSurfaceAutomatically = false
        }

        public func show(in parentView: UIView, frame: CGRect) {
            let hostView = parentView.window ?? parentView
            let hostFrame = parentView === hostView ? frame : parentView.convert(frame, to: hostView)
            let floatingView = floatingView ?? FloatingPlaybackView(frame: frame)
            self.floatingView = floatingView
            floatingView.frame = hostFrame
            floatingView.closeAction = { [weak self] in
                self?.close()
            }

            if floatingView.superview !== hostView {
                hostView.addSubview(floatingView)
            }

            legacyPlayerView?.removeFromSuperview()
            floatingView.attach(renderView)
            renderView.activateRenderSurface()
            installFloatingControls(in: floatingView)
            isVisible = true
        }

        public func setCloseHandler(_ handler: (() -> Void)?) {
            closeHandler = handler
        }

        public func hide() {
            uninstallFloatingControls()
            floatingView?.detach()
            floatingView?.removeFromSuperview()
            floatingView = nil
            isVisible = false
        }

        private func installFloatingControls(in floatingView: FloatingPlaybackView) {
            floatingOverlay.closeAction = { [weak self] in
                self?.close()
            }

            guard controlView.superview !== floatingView else { return }
            uninstallFloatingControls()
            controlView.translatesAutoresizingMaskIntoConstraints = false
            floatingView.addSubview(controlView)
            controlViewConstraints = [
                controlView.topAnchor.constraint(equalTo: floatingView.topAnchor),
                controlView.leadingAnchor.constraint(equalTo: floatingView.leadingAnchor),
                controlView.trailingAnchor.constraint(equalTo: floatingView.trailingAnchor),
                controlView.bottomAnchor.constraint(equalTo: floatingView.bottomAnchor),
            ]
            NSLayoutConstraint.activate(controlViewConstraints)
        }

        private func uninstallFloatingControls() {
            NSLayoutConstraint.deactivate(controlViewConstraints)
            controlViewConstraints.removeAll()
            controlView.removeFromSuperview()
        }

        private func close() {
            closeHandler?()
            hide()
        }
    }
#endif
