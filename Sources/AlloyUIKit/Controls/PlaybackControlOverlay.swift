//
//  PlaybackControlOverlay.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import UIKit

    /// 播放控制层。
    @MainActor
    public protocol PlaybackControlOverlay: AnyObject {
        var actionHandler: ((PlaybackControlAction) -> Void)? { get set }
        func render(state: PlaybackStateSnapshot)
        func handle(event: PlaybackEvent)
        func render(fullscreenState: FullscreenState)
        func handle(gesture: GestureEvent)
        func shouldReceiveGesture(_ type: GestureType, recognizer: UIGestureRecognizer, touch: UITouch) -> Bool
    }

    public extension PlaybackControlOverlay {
        func render(fullscreenState _: FullscreenState) {}
        func handle(gesture _: GestureEvent) {}
        func shouldReceiveGesture(_: GestureType, recognizer _: UIGestureRecognizer, touch _: UITouch) -> Bool {
            true
        }
    }
#endif
