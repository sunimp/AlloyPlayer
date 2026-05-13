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
        var closeAction: (() -> Void)?
        weak var contentView: UIView?
        private var contentConstraints: [NSLayoutConstraint] = []
        private var panStartCenter = CGPoint.zero

        private lazy var closeButton: UIButton = {
            let button = UIButton(type: .system)
            let configuration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: configuration), for: .normal)
            button.tintColor = .white
            button.backgroundColor = UIColor.black.withAlphaComponent(0.35)
            button.layer.cornerRadius = 15
            button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
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
            detach()
            contentView = view
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
        }

        func detach() {
            NSLayoutConstraint.deactivate(contentConstraints)
            contentConstraints.removeAll()
            contentView?.removeFromSuperview()
            contentView = nil
        }

        private func configureView() {
            backgroundColor = .black
            layer.cornerRadius = 8
            layer.masksToBounds = true

            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            addGestureRecognizer(panGesture)

            addSubview(closeButton)
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 6),
                closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
                closeButton.widthAnchor.constraint(equalToConstant: 30),
                closeButton.heightAnchor.constraint(equalToConstant: 30),
            ])
        }

        @objc private func closeButtonTapped() {
            closeAction?()
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
    }
#endif
