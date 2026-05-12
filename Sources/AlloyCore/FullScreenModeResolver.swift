//
//  FullScreenModeResolver.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/12.
//

import CoreGraphics

/// 全屏模式解析器。
public enum FullScreenModeResolver {
    public static func resolve(mode: FullScreenMode, presentationSize: CGSize) -> FullScreenMode {
        switch mode {
        case .landscape, .portrait:
            mode
        case .automatic:
            presentationSize.width > presentationSize.height ? .landscape : .portrait
        }
    }
}
