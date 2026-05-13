//
//  PlaybackControlOverlay.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import UIKit

    /// 播放控制层布局模式。
    public enum PlaybackControlLayout: Equatable, Sendable {
        case inline
        case fullscreenPortrait
        case fullscreenLandscape
    }

    /// 播放控制层渲染上下文。
    public struct PlaybackControlContext: Equatable, Sendable {
        public var state: PlaybackStateSnapshot
        public var fullscreenState: FullscreenState
        public var fullscreenMode: FullscreenMode
        public var layout: PlaybackControlLayout

        public init(
            state: PlaybackStateSnapshot,
            fullscreenState: FullscreenState = .inline,
            fullscreenMode: FullscreenMode = .automatic,
            layout: PlaybackControlLayout = .inline
        ) {
            self.state = state
            self.fullscreenState = fullscreenState
            self.fullscreenMode = fullscreenMode
            self.layout = layout
        }
    }

    /// 播放控制层输入事件。
    public enum PlaybackControlInput: Equatable, Sendable {
        case playbackEvent(PlaybackEvent)
        case gesture(GestureEvent)
    }

    /// 播放控制层。
    @MainActor
    public protocol PlaybackControlOverlay: AnyObject {
        var actionHandler: ((PlaybackControlAction) -> Void)? { get set }
        func render(context: PlaybackControlContext)
        func handle(input: PlaybackControlInput)
        func shouldReceiveGesture(_ type: GestureType, recognizer: UIGestureRecognizer, touch: UITouch) -> Bool
    }

    public extension PlaybackControlOverlay {
        func handle(input _: PlaybackControlInput) {}

        func shouldReceiveGesture(_: GestureType, recognizer _: UIGestureRecognizer, touch _: UITouch) -> Bool {
            true
        }
    }
#endif
