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

            orientationWillChange?(orientation)

            let isToFullScreen = orientation.isLandscape
            let previousOrientation = currentOrientation
            currentOrientation = orientation

            if isToFullScreen {
                rotateToLandscape(orientation: orientation, animated: animated) { [weak self] in
                    self?.orientationDidChange?(orientation)
                    completion?()
                }
            } else {
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
            completion: @escaping () -> Void
        ) {
            guard let contentView else {
                completion()
                return
            }

            let controller = ensureLandscapeController()
            let window = ensureWindow()

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
            controller.view.addSubview(contentView)

            UIView.animate(withDuration: duration, animations: {
                contentView.frame = controller.view.bounds
            }, completion: { _ in
                completion()
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

            UIView.animate(withDuration: duration, animations: {
                contentView.frame = containerView.bounds
            }, completion: { [weak self] _ in
                containerView.addSubview(contentView)
                contentView.frame = containerView.bounds
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

        private func ensureWindow() -> LandscapeWindow {
            if let existing = window { return existing }
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first
            else {
                fatalError("No UIWindowScene available")
            }
            let win = LandscapeWindow(windowScene: scene)
            win.rotationHandler = self
            win.rootViewController = landscapeController
            win.isHidden = false
            win.makeKeyAndVisible()
            window = win
            return win
        }

        private func cleanupWindow() {
            window?.isHidden = true
            window?.rootViewController = nil
            window = nil
            landscapeController = nil
        }
    }
#endif
