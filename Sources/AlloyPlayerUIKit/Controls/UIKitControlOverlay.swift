//
//  UIKitControlOverlay.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import UIKit

    /// UIKit 播放控制层。
    @MainActor
    public protocol UIKitControlOverlay: PlaybackControlOverlay where Self: UIView {}
#endif
