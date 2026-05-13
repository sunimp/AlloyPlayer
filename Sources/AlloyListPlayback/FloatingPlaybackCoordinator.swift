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

        public init(playerView: AlloyUIKit.AlloyPlayerView) {
            self.playerView = playerView
        }

        public func show(in parentView: UIView, frame: CGRect) {
            let floatingView = floatingView ?? FloatingPlaybackView(frame: frame)
            self.floatingView = floatingView
            floatingView.frame = frame

            if floatingView.superview !== parentView {
                parentView.addSubview(floatingView)
            }

            floatingView.attach(playerView)
            isVisible = true
        }

        public func hide() {
            floatingView?.detach()
            floatingView?.removeFromSuperview()
            floatingView = nil
            isVisible = false
        }
    }
#endif
