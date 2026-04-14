//
//  LandscapeWindow.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    /// 横屏全屏专用窗口
    final class LandscapeWindow: UIWindow {
        weak var rotationHandler: LandscapeRotationHandler?

        override init(windowScene: UIWindowScene) {
            super.init(windowScene: windowScene)
            backgroundColor = .black
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
#endif
