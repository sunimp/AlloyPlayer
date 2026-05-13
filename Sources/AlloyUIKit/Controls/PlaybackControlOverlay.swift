//
//  PlaybackControlOverlay.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore

    /// 播放控制层。
    @MainActor
    public protocol PlaybackControlOverlay: AnyObject {
        var actionHandler: ((PlaybackControlAction) -> Void)? { get set }
        func render(state: PlaybackStateSnapshot)
        func handle(event: PlaybackEvent)
    }
#endif
