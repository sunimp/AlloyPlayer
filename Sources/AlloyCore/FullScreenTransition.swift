//
//  FullScreenTransition.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    /// 全屏转场动画
    final class FullScreenTransition: NSObject, UIViewControllerAnimatedTransitioning {
        let isPresenting: Bool
        let contentView: UIView
        let containerView: UIView
        var duration: TimeInterval = 0.3

        init(isPresenting: Bool, contentView: UIView, containerView: UIView) {
            self.isPresenting = isPresenting
            self.contentView = contentView
            self.containerView = containerView
            super.init()
        }

        func transitionDuration(using _: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
            duration
        }

        func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
            if isPresenting {
                animatePresent(using: transitionContext)
            } else {
                animateDismiss(using: transitionContext)
            }
        }

        private func animatePresent(using context: any UIViewControllerContextTransitioning) {
            guard let toView = context.view(forKey: .to) else {
                context.completeTransition(false)
                return
            }

            let container = context.containerView
            container.addSubview(toView)
            toView.frame = container.bounds

            // 记录原始 frame
            let startFrame = containerView.convert(containerView.bounds, to: container)
            contentView.frame = startFrame

            container.addSubview(contentView)

            UIView.animate(withDuration: duration, animations: {
                self.contentView.frame = container.bounds
            }, completion: { _ in
                toView.addSubview(self.contentView)
                self.contentView.frame = toView.bounds
                context.completeTransition(!context.transitionWasCancelled)
            })
        }

        private func animateDismiss(using context: any UIViewControllerContextTransitioning) {
            let container = context.containerView
            let targetFrame = containerView.convert(containerView.bounds, to: container)

            container.addSubview(contentView)
            contentView.frame = container.bounds

            UIView.animate(withDuration: duration, animations: {
                self.contentView.frame = targetFrame
            }, completion: { _ in
                self.containerView.addSubview(self.contentView)
                self.contentView.frame = self.containerView.bounds
                context.completeTransition(!context.transitionWasCancelled)
            })
        }
    }
#endif
