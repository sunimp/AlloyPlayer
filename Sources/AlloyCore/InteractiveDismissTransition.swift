//
//  InteractiveDismissTransition.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    /// 交互式退出转场
    ///
    /// 通过手势驱动竖屏全屏的退出动画。
    final class InteractiveDismissTransition: UIPercentDrivenInteractiveTransition {
        // MARK: - 状态

        var isInteracting = false
        var disabledPortraitGestureTypes: DisablePortraitGestureTypes = []

        // MARK: - 视图

        weak var contentView: UIView?
        weak var containerView: UIView?
        weak var viewController: UIViewController?

        // MARK: - 内部

        private var panGesture: UIPanGestureRecognizer?
        private var startPoint: CGPoint = .zero

        // MARK: - 方法

        func updateViews(contentView: UIView, containerView: UIView) {
            self.contentView = contentView
            self.containerView = containerView
            setupPanGesture()
        }

        private func setupPanGesture() {
            guard !disabledPortraitGestureTypes.contains(.pan) else { return }
            if let old = panGesture {
                contentView?.removeGestureRecognizer(old)
            }
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            contentView?.addGestureRecognizer(pan)
            panGesture = pan
        }

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            let translation = gesture.translation(in: view)
            let progress = min(max(translation.y / view.bounds.height, 0), 1)

            switch gesture.state {
            case .began:
                isInteracting = true
                startPoint = gesture.location(in: view)
                viewController?.dismiss(animated: true)

            case .changed:
                update(progress)

            case .ended, .cancelled:
                isInteracting = false
                if progress > 0.3 || gesture.velocity(in: view).y > 500 {
                    finish()
                } else {
                    cancel()
                }

            default:
                break
            }
        }
    }
#endif
