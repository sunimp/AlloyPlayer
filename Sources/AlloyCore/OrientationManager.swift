//
//  OrientationManager.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import Combine
    import UIKit

    /// 屏幕旋转管理器
    ///
    /// 协调横屏旋转和竖屏全屏两种全屏方式。
    @MainActor
    public final class OrientationManager {
        // MARK: - 视图

        /// 容器视图
        public weak var containerView: UIView?

        /// 全屏容器视图
        public var fullScreenContainerView: UIView? {
            if isFullScreen {
                return fullScreenMode == .portrait
                    ? portraitController?.view
                    : landscapeHandler.fullScreenContainerView
            }
            return nil
        }

        // MARK: - 状态

        /// 是否处于全屏
        public private(set) var isFullScreen = false

        /// 当前屏幕方向
        public private(set) var currentOrientation: UIInterfaceOrientation = .portrait

        // MARK: - 配置

        /// 全屏模式
        public var fullScreenMode: FullScreenMode = .automatic

        /// 竖屏全屏模式
        public var portraitFullScreenMode: PortraitFullScreenMode = .scaleAspectFit

        /// 动画时长
        public var animationDuration: TimeInterval = 0.3

        /// 锁屏
        public var isScreenLocked = false {
            didSet { landscapeHandler.isScreenLocked = isScreenLocked }
        }

        /// 是否允许旋转
        public var isAllowOrientationRotation = true {
            didSet { landscapeHandler.isAllowOrientationRotation = isAllowOrientationRotation }
        }

        /// 支持的方向
        public var supportedOrientations: InterfaceOrientationMask = .allButUpsideDown {
            didSet { landscapeHandler.supportedOrientations = supportedOrientations }
        }

        /// 全屏状态栏隐藏
        public var isFullScreenStatusBarHidden = true

        /// 全屏状态栏样式
        public var fullScreenStatusBarStyle: UIStatusBarStyle = .lightContent

        /// 全屏状态栏动画
        public var fullScreenStatusBarAnimation: UIStatusBarAnimation = .fade

        /// 视频尺寸
        public var presentationSize: CGSize = .zero

        /// 竖屏全屏禁用手势类型
        public var disabledPortraitGestureTypes: DisablePortraitGestureTypes = []

        // MARK: - Combine

        private let _orientationWillChange = PassthroughSubject<Bool, Never>()
        private let _orientationDidChange = PassthroughSubject<Bool, Never>()

        /// 即将旋转 (参数: isFullScreen)
        public var orientationWillChangePublisher: AnyPublisher<Bool, Never> {
            _orientationWillChange.eraseToAnyPublisher()
        }

        /// 旋转完成 (参数: isFullScreen)
        public var orientationDidChangePublisher: AnyPublisher<Bool, Never> {
            _orientationDidChange.eraseToAnyPublisher()
        }

        // MARK: - 内部

        private let landscapeHandler = LandscapeRotationHandler()
        private var portraitController: PortraitController?
        private var deviceOrientationObserver: NSObjectProtocol?

        // MARK: - 初始化

        public init() {
            landscapeHandler.orientationWillChange = { [weak self] _ in
                guard let self else { return }
                let willBeFullScreen = !self.isFullScreen
                self._orientationWillChange.send(willBeFullScreen)
            }
            landscapeHandler.orientationDidChange = { [weak self] orientation in
                guard let self else { return }
                self.isFullScreen = orientation.isLandscape
                self.currentOrientation = orientation
                self._orientationDidChange.send(self.isFullScreen)
            }
        }

        // MARK: - 视图绑定

        /// 更新渲染视图与容器视图
        public func updateViews(renderView: RenderView, containerView: UIView) {
            self.containerView = containerView
            landscapeHandler.updateViews(contentView: renderView, containerView: containerView)
        }

        // MARK: - 设备方向监听

        /// 开始监听设备方向变化
        public func addDeviceOrientationObserver() {
            guard deviceOrientationObserver == nil else { return }
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            landscapeHandler.isActiveDeviceObserver = true

            deviceOrientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.landscapeHandler.handleDeviceOrientationChange()
            }
        }

        /// 停止监听设备方向变化
        public func removeDeviceOrientationObserver() {
            landscapeHandler.isActiveDeviceObserver = false
            if let observer = deviceOrientationObserver {
                NotificationCenter.default.removeObserver(observer)
                deviceOrientationObserver = nil
            }
        }

        // MARK: - 旋转方法

        /// 旋转到指定方向
        public func rotate(to orientation: UIInterfaceOrientation, animated: Bool) async {
            await withCheckedContinuation { continuation in
                rotate(to: orientation, animated: animated) {
                    continuation.resume()
                }
            }
        }

        /// 旋转到指定方向（带回调）
        public func rotate(to orientation: UIInterfaceOrientation, animated: Bool, completion: (() -> Void)?) {
            landscapeHandler.rotate(to: orientation, animated: animated, completion: completion)
        }

        /// 进入/退出竖屏全屏
        public func enterPortraitFullScreen(_ fullScreen: Bool, animated: Bool) async {
            await withCheckedContinuation { continuation in
                enterPortraitFullScreen(fullScreen, animated: animated) {
                    continuation.resume()
                }
            }
        }

        private func enterPortraitFullScreen(_ fullScreen: Bool, animated: Bool, completion: (() -> Void)?) {
            _orientationWillChange.send(fullScreen)

            if fullScreen {
                presentPortraitFullScreen(animated: animated) { [weak self] in
                    self?.isFullScreen = true
                    self?._orientationDidChange.send(true)
                    completion?()
                }
            } else {
                dismissPortraitFullScreen(animated: animated) { [weak self] in
                    self?.isFullScreen = false
                    self?._orientationDidChange.send(false)
                    completion?()
                }
            }
        }

        /// 智能进入/退出全屏（根据 fullScreenMode 自动选择横屏或竖屏）
        public func enterFullScreen(_ fullScreen: Bool, animated: Bool) async {
            switch fullScreenMode {
            case .landscape:
                if fullScreen {
                    await rotate(to: .landscapeRight, animated: animated)
                } else {
                    await rotate(to: .portrait, animated: animated)
                }
            case .portrait:
                await enterPortraitFullScreen(fullScreen, animated: animated)
            case .automatic:
                // 根据视频宽高比选择：宽 > 高 → 横屏，否则竖屏
                if presentationSize.width > presentationSize.height {
                    if fullScreen {
                        await rotate(to: .landscapeRight, animated: animated)
                    } else {
                        await rotate(to: .portrait, animated: animated)
                    }
                } else {
                    await enterPortraitFullScreen(fullScreen, animated: animated)
                }
            }
        }

        // MARK: - 竖屏全屏内部方法

        private func presentPortraitFullScreen(animated: Bool, completion: (() -> Void)?) {
            guard let containerView, let contentView = landscapeHandler.contentView else {
                completion?()
                return
            }

            let controller = PortraitController()
            controller.contentView = contentView
            controller.containerView = containerView
            controller.animationDuration = animationDuration
            controller.presentationSize = presentationSize
            controller.disabledPortraitGestureTypes = disabledPortraitGestureTypes
            controller.isStatusBarHidden = isFullScreenStatusBarHidden
            controller.statusBarStyle = fullScreenStatusBarStyle
            controller.modalPresentationStyle = .custom
            portraitController = controller

            guard let presenting = UIApplication.shared.topViewController else {
                completion?()
                return
            }

            presenting.present(controller, animated: animated) {
                completion?()
            }
        }

        private func dismissPortraitFullScreen(animated: Bool, completion: (() -> Void)?) {
            portraitController?.dismiss(animated: animated) { [weak self] in
                self?.portraitController = nil
                completion?()
            }
        }

        deinit {
            if let observer = deviceOrientationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    // MARK: - UIApplication 扩展（查找顶层 VC）

    private extension UIApplication {
        @MainActor
        var topViewController: UIViewController? {
            guard let scene = connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
                var top = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            else { return nil }

            while let presented = top.presentedViewController {
                top = presented
            }
            return top
        }
    }
#endif
