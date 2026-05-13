//
//  FloatingPlaybackView.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import UIKit

    @MainActor
    final class FloatingPlaybackView: UIView {
        weak var contentView: UIView?
        private var contentConstraints: [NSLayoutConstraint] = []

        func attach(_ view: UIView) {
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

        func detach() {
            NSLayoutConstraint.deactivate(contentConstraints)
            contentConstraints.removeAll()
            contentView?.removeFromSuperview()
            contentView = nil
        }
    }
#endif
