//
//  FloatingPlaybackView.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import UIKit

    @MainActor
    public final class FloatingPlaybackView: UIView {
        public weak var contentView: UIView?
        private var contentConstraints: [NSLayoutConstraint] = []

        public func attach(_ view: UIView) {
            detach()
            contentView = view
            view.removeFromSuperview()
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            contentConstraints = [
                view.topAnchor.constraint(equalTo: topAnchor),
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor),
            ]
            NSLayoutConstraint.activate(contentConstraints)
        }

        public func detach() {
            NSLayoutConstraint.deactivate(contentConstraints)
            contentConstraints.removeAll()
            contentView?.removeFromSuperview()
            contentView = nil
        }
    }
#endif
