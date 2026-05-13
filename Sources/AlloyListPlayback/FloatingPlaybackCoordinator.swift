//
//  FloatingPlaybackCoordinator.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyUIKit
    import UIKit

    @MainActor
    public final class FloatingPlaybackCoordinator {
        public let playerView: AlloyUIKit.AlloyPlayerView
        public private(set) var isVisible = false

        private var floatingView: FloatingPlaybackView?
        private var closeHandler: (() -> Void)?

        public init(playerView: AlloyUIKit.AlloyPlayerView) {
            self.playerView = playerView
        }

        public func show(in parentView: UIView, frame: CGRect) {
            let hostView = parentView.window ?? parentView
            let hostFrame = parentView === hostView ? frame : parentView.convert(frame, to: hostView)
            let floatingView = floatingView ?? FloatingPlaybackView(frame: frame)
            self.floatingView = floatingView
            floatingView.frame = hostFrame
            floatingView.closeAction = { [weak self] in
                self?.closeHandler?()
                self?.hide()
            }

            if floatingView.superview !== hostView {
                hostView.addSubview(floatingView)
            }

            floatingView.attach(playerView)
            isVisible = true
        }

        public func setCloseHandler(_ handler: (() -> Void)?) {
            closeHandler = handler
        }

        public func hide() {
            floatingView?.detach()
            floatingView?.removeFromSuperview()
            floatingView = nil
            isVisible = false
        }
    }
#endif
