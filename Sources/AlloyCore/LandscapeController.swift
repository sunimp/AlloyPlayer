//
//  LandscapeController.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    /// 横屏全屏视图控制器
    final class LandscapeController: UIViewController {
        // MARK: - 配置

        var isDisableAnimations = false
        var isStatusBarHidden = false
        var statusBarStyle: UIStatusBarStyle = .lightContent
        var statusBarAnimation: UIStatusBarAnimation = .fade

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

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            .allButUpsideDown
        }

        override var shouldAutorotate: Bool {
            true
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
        }
    }
#endif
