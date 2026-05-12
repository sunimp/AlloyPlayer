//
//  LandscapeRotationHandler.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    /// 横屏旋转处理器
    ///
    /// 内部按 iOS 版本差异分策略：
    /// - iOS 16+: 基于 `UIWindowScene.requestGeometryUpdate`
    /// - iOS 15: 基于 `UIDevice.setValue` + `supportedInterfaceOrientations`
    @MainActor
    final class LandscapeRotationHandler {
        // MARK: - 状态

        var currentOrientation: UIInterfaceOrientation = .portrait
        var isAllowOrientationRotation = true
        var isScreenLocked = false
        var isDisableAnimations = false
        var supportedOrientations: InterfaceOrientationMask = .allButUpsideDown
        var isActiveDeviceObserver = false

        // MARK: - 视图

        weak var contentView: UIView?
        weak var containerView: UIView?
        var windowSceneProvider: () -> UIWindowScene? = {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first
        }

        private var window: LandscapeWindow?
        private var landscapeController: LandscapeController?

        // MARK: - 回调

        var orientationWillChange: ((UIInterfaceOrientation) -> Void)?
        var orientationDidChange: ((UIInterfaceOrientation) -> Void)?

        // MARK: - 方法

        func updateViews(contentView: UIView, containerView: UIView) {
            self.contentView = contentView
            self.containerView = containerView
        }

        var fullScreenContainerView: UIView? {
            landscapeController?.view
        }

        /// 旋转到指定方向
        func rotate(
            to orientation: UIInterfaceOrientation,
            animated: Bool,
            completion: (() -> Void)? = nil
        ) {
            guard isAllowOrientationRotation, !isScreenLocked else {
                completion?()
                return
            }
            guard isSupported(orientation) else {
                completion?()
                return
            }
            guard orientation != currentOrientation else {
                completion?()
                return
            }

            let isToFullScreen = orientation.isLandscape
            let previousOrientation = currentOrientation

            if isToFullScreen {
                rotateToLandscape(orientation: orientation, animated: animated) { [weak self] success in
                    guard success else {
                        completion?()
                        return
                    }
                    self?.currentOrientation = orientation
                    self?.orientationDidChange?(orientation)
                    completion?()
                }
            } else {
                orientationWillChange?(orientation)
                currentOrientation = orientation
                rotateToPortrait(from: previousOrientation, animated: animated) { [weak self] in
                    self?.orientationDidChange?(orientation)
                    completion?()
                }
            }
        }

        /// 处理设备方向变化
        func handleDeviceOrientationChange() {
            guard isActiveDeviceObserver, isAllowOrientationRotation, !isScreenLocked else { return }

            let deviceOrientation = UIDevice.current.orientation
            let interfaceOrientation: UIInterfaceOrientation
            switch deviceOrientation {
            case .portrait: interfaceOrientation = .portrait
            case .landscapeLeft: interfaceOrientation = .landscapeRight
            case .landscapeRight: interfaceOrientation = .landscapeLeft
            case .portraitUpsideDown: interfaceOrientation = .portraitUpsideDown
            default: return
            }

            guard isSupported(interfaceOrientation) else { return }
            rotate(to: interfaceOrientation, animated: true)
        }

        // MARK: - 内部方法

        private func isSupported(_ orientation: UIInterfaceOrientation) -> Bool {
            switch orientation {
            case .portrait: supportedOrientations.contains(.portrait)
            case .landscapeLeft: supportedOrientations.contains(.landscapeLeft)
            case .landscapeRight: supportedOrientations.contains(.landscapeRight)
            case .portraitUpsideDown: supportedOrientations.contains(.portraitUpsideDown)
            default: false
            }
        }

        private func rotateToLandscape(
            orientation: UIInterfaceOrientation,
            animated: Bool,
            completion: @escaping (Bool) -> Void
        ) {
            guard let contentView else {
                completion(false)
                return
            }

            let controller = ensureLandscapeController()
            guard let window = ensureWindow() else {
                completion(false)
                return
            }

            orientationWillChange?(orientation)

            // 在 iOS 16+ 使用 requestGeometryUpdate
            if #available(iOS 16.0, *) {
                let mask: UIInterfaceOrientationMask = orientation == .landscapeLeft ? .landscapeLeft : .landscapeRight
                let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
                window.windowScene?.requestGeometryUpdate(preferences)
                controller.setNeedsUpdateOfSupportedInterfaceOrientations()
            } else {
                UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
            }

            let duration = animated ? 0.3 : 0.0

            // 使用 frame-based 布局（跨窗口迁移时比 Auto Layout 更可靠）
            deactivateSuperviewConstraints(for: contentView)
            contentView.translatesAutoresizingMaskIntoConstraints = true
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            controller.view.addSubview(contentView)
            contentView.frame = controller.view.bounds

            window.alpha = 0
            UIView.animate(withDuration: duration, animations: {
                window.alpha = 1
            }, completion: { _ in
                completion(true)
            })
        }

        private func rotateToPortrait(
            from _: UIInterfaceOrientation,
            animated: Bool,
            completion: @escaping () -> Void
        ) {
            guard let contentView, let containerView else {
                completion()
                return
            }
            if #available(iOS 16.0, *) {
                let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                window?.windowScene?.requestGeometryUpdate(preferences)
                landscapeController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }

            let duration = animated ? 0.3 : 0.0
            containerView.layoutIfNeeded()

            deactivateSuperviewConstraints(for: contentView)
            contentView.translatesAutoresizingMaskIntoConstraints = true
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            containerView.addSubview(contentView)
            contentView.frame = containerView.bounds

            UIView.animate(withDuration: duration, animations: {
                self.window?.alpha = 0
            }, completion: { [weak self] _ in
                self?.cleanupWindow()
                completion()
            })
        }

        private func ensureLandscapeController() -> LandscapeController {
            if let existing = landscapeController { return existing }
            let controller = LandscapeController()
            landscapeController = controller
            return controller
        }

        private func ensureWindow() -> LandscapeWindow? {
            if let existing = window { return existing }
            guard let scene = windowSceneProvider() else { return nil }
            let win = LandscapeWindow(windowScene: scene)
            win.rotationHandler = self
            win.rootViewController = landscapeController
            win.isHidden = false
            win.makeKeyAndVisible()
            window = win
            return win
        }

        private func deactivateSuperviewConstraints(for view: UIView) {
            guard let superview = view.superview else { return }
            let constraints = superview.constraints.filter {
                $0.firstItem === view || $0.secondItem === view
            }
            NSLayoutConstraint.deactivate(constraints)
        }

        private func cleanupWindow() {
            window?.isHidden = true
            window?.rootViewController = nil
            window = nil
            landscapeController = nil
        }
    }
#endif
