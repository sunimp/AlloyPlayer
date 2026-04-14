//
//  PortraitController.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import Combine
    import UIKit

    /// 竖屏全屏视图控制器
    ///
    /// 通过 modal present 实现竖屏全屏效果。
    final class PortraitController: UIViewController {
        // MARK: - 视图

        /// 播放器内容视图
        var contentView: UIView?

        /// 原始容器视图
        var containerView: UIView?

        // MARK: - 配置

        var isStatusBarHidden = false
        var statusBarStyle: UIStatusBarStyle = .lightContent
        var statusBarAnimation: UIStatusBarAnimation = .fade
        var disabledPortraitGestureTypes: DisablePortraitGestureTypes = []
        var presentationSize: CGSize = .zero
        var isFullScreenAnimation = true
        var animationDuration: TimeInterval = 0.3

        // MARK: - 回调

        var orientationWillChange: ((Bool) -> Void)?
        var orientationDidChange: ((Bool) -> Void)?

        // MARK: - 内部

        private var fullScreenTransition: FullScreenTransition?
        private var interactiveTransition: InteractiveDismissTransition?

        // MARK: - 重写

        override var prefersStatusBarHidden: Bool {
            isStatusBarHidden
        }

        override var preferredStatusBarStyle: UIStatusBarStyle {
            statusBarStyle
        }

        override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
            statusBarAnimation
        }

        override var shouldAutorotate: Bool {
            false
        }

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            .portrait
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
        }
    }

    // MARK: - UIViewControllerTransitioningDelegate

    extension PortraitController: UIViewControllerTransitioningDelegate {
        func animationController(
            forPresented _: UIViewController,
            presenting _: UIViewController,
            source _: UIViewController
        ) -> (any UIViewControllerAnimatedTransitioning)? {
            guard let contentView, let containerView else { return nil }
            let transition = FullScreenTransition(isPresenting: true, contentView: contentView, containerView: containerView)
            transition.duration = animationDuration
            fullScreenTransition = transition
            return transition
        }

        func animationController(forDismissed _: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
            guard let contentView, let containerView else { return nil }
            let transition = FullScreenTransition(isPresenting: false, contentView: contentView, containerView: containerView)
            transition.duration = animationDuration
            fullScreenTransition = transition
            return transition
        }

        func interactionControllerForDismissal(
            using _: any UIViewControllerAnimatedTransitioning
        ) -> (any UIViewControllerInteractiveTransitioning)? {
            guard let interactiveTransition, interactiveTransition.isInteracting else { return nil }
            return interactiveTransition
        }
    }
#endif
