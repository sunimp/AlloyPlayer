//
//  Player+Orientation.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    // MARK: - 旋转/全屏扩展

    public extension Player {
        /// 允许旋转
        var isAllowOrientationRotation: Bool {
            get { orientationManager.isAllowOrientationRotation }
            set { orientationManager.isAllowOrientationRotation = newValue }
        }

        /// 开始监听设备方向变化
        func addDeviceOrientationObserver() {
            orientationManager.addDeviceOrientationObserver()
        }

        /// 停止监听设备方向变化
        func removeDeviceOrientationObserver() {
            orientationManager.removeDeviceOrientationObserver()
        }

        /// 旋转到指定方向
        func rotate(to orientation: UIInterfaceOrientation, animated: Bool) async {
            await orientationManager.rotate(to: orientation, animated: animated)
        }

        /// 进入/退出竖屏全屏
        func enterPortraitFullScreen(_ fullScreen: Bool, animated: Bool) async {
            await orientationManager.enterPortraitFullScreen(fullScreen, animated: animated)
        }

        /// 智能进入/退出全屏
        func enterFullScreen(_ fullScreen: Bool, animated: Bool) async {
            await orientationManager.enterFullScreen(fullScreen, animated: animated)
        }
    }
#endif
