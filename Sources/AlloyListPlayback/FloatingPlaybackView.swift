//
//  FloatingPlaybackView.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyUIKit
    import UIKit

    @MainActor
    final class FloatingPlaybackView: UIView, UIGestureRecognizerDelegate {
        var closeAction: (() -> Void)?
        weak var contentView: UIView?
        private var contentConstraints: [NSLayoutConstraint] = []
        private var panStartCenter = CGPoint.zero

        private lazy var panGesture: UIPanGestureRecognizer = {
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            gesture.delegate = self
            return gesture
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            configureView()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func attach(_ view: UIView) {
            UIView.performWithoutAnimation {
                detach()
                contentView = view
                deactivateSuperviewConstraints(for: view)
                view.removeFromSuperview()
                view.translatesAutoresizingMaskIntoConstraints = false
                insertSubview(view, at: 0)
                contentConstraints = [
                    view.topAnchor.constraint(equalTo: topAnchor),
                    view.leadingAnchor.constraint(equalTo: leadingAnchor),
                    view.trailingAnchor.constraint(equalTo: trailingAnchor),
                    view.bottomAnchor.constraint(equalTo: bottomAnchor),
                ]
                NSLayoutConstraint.activate(contentConstraints)
                layoutIfNeeded()
            }
        }

        func detach() {
            UIView.performWithoutAnimation {
                NSLayoutConstraint.deactivate(contentConstraints)
                contentConstraints.removeAll()
                contentView?.removeFromSuperview()
                contentView = nil
                layoutIfNeeded()
            }
        }

        private func configureView() {
            backgroundColor = .black
            layer.cornerRadius = 8
            layer.masksToBounds = true
            addGestureRecognizer(panGesture)
        }

        private func deactivateSuperviewConstraints(for view: UIView) {
            guard let superview = view.superview else { return }
            let constraints = superview.constraints.filter { constraint in
                constraint.firstItem === view || constraint.secondItem === view
            }
            NSLayoutConstraint.deactivate(constraints)
        }

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let superview else { return }
            switch gesture.state {
            case .began:
                panStartCenter = center
            case .changed, .ended:
                let translation = gesture.translation(in: superview)
                center = clampedCenter(
                    CGPoint(x: panStartCenter.x + translation.x, y: panStartCenter.y + translation.y),
                    in: superview
                )
                panStartCenter = center
                gesture.setTranslation(.zero, in: superview)
            default:
                break
            }
        }

        private func clampedCenter(_ proposedCenter: CGPoint, in superview: UIView) -> CGPoint {
            let halfWidth = bounds.width / 2
            let halfHeight = bounds.height / 2
            let safeBounds = superview.bounds.inset(by: superview.safeAreaInsets)
            let minX = safeBounds.minX + halfWidth
            let maxX = safeBounds.maxX - halfWidth
            let minY = safeBounds.minY + halfHeight
            let maxY = safeBounds.maxY - halfHeight
            guard minX <= maxX, minY <= maxY else {
                return CGPoint(x: safeBounds.midX, y: safeBounds.midY)
            }

            return CGPoint(
                x: min(max(proposedCenter.x, minX), maxX),
                y: min(max(proposedCenter.y, minY), maxY)
            )
        }

        func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            !isControlTouch(touch)
        }

        func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
            true
        }

        private func isControlTouch(_ touch: UITouch) -> Bool {
            var touchedView = touch.view
            while let view = touchedView, view !== self {
                if view is UIControl || view is ProgressSlider {
                    return true
                }
                touchedView = view.superview
            }
            return false
        }
    }
#endif
