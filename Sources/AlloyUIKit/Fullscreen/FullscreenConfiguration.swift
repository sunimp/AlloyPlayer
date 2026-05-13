//
//  FullscreenConfiguration.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import UIKit

    public enum FullscreenMode: Equatable, Sendable {
        case automatic
        case landscape
        case portrait
    }

    public enum PortraitFullscreenMode: Equatable, Sendable {
        case scaleToFill
        case scaleAspectFit
    }

    public struct FullscreenConfiguration: Equatable, Sendable {
        public var mode: FullscreenMode
        public var portraitMode: PortraitFullscreenMode
        public var statusBarStyle: UIStatusBarStyle

        public init(
            mode: FullscreenMode = .automatic,
            portraitMode: PortraitFullscreenMode = .scaleAspectFit,
            statusBarStyle: UIStatusBarStyle = .lightContent
        ) {
            self.mode = mode
            self.portraitMode = portraitMode
            self.statusBarStyle = statusBarStyle
        }
    }
#endif
