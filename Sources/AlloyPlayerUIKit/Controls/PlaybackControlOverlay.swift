//
//  PlaybackControlOverlay.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import UIKit

    /// 播放控制层布局模式。
    public enum PlaybackControlLayout: Equatable, Sendable {
        /// 嵌入式播放布局。
        case inline

        /// 竖屏全屏布局。
        case fullscreenPortrait

        /// 横屏全屏布局。
        case fullscreenLandscape
    }

    /// 播放控制层渲染上下文。
    public struct PlaybackControlContext: Equatable, Sendable {
        /// 播放会话状态快照。
        public var state: PlaybackStateSnapshot

        /// 当前全屏状态。
        public var fullscreenState: FullscreenState

        /// 当前全屏模式。
        public var fullscreenMode: FullscreenMode

        /// 当前控制层布局。
        public var layout: PlaybackControlLayout

        /// 创建播放控制层渲染上下文。
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
        /// 播放会话事件输入。
        case playbackEvent(PlaybackEvent)

        /// 手势事件输入。
        case gesture(GestureEvent)
    }

    /// 播放控制层。
    @MainActor
    public protocol PlaybackControlOverlay: AnyObject {
        /// 控制层动作回调。
        var actionHandler: ((PlaybackControlAction) -> Void)? { get set }

        /// 根据上下文渲染控制层状态。
        func render(context: PlaybackControlContext)

        /// 处理播放或手势输入。
        func handle(input: PlaybackControlInput)

        /// 判断是否接收指定手势。
        func shouldReceiveGesture(_ type: GestureType, recognizer: UIGestureRecognizer, touch: UITouch) -> Bool
    }

    /// 播放控制层默认行为。
    public extension PlaybackControlOverlay {
        /// 默认忽略输入事件。
        func handle(input _: PlaybackControlInput) {}

        /// 默认接收所有手势。
        func shouldReceiveGesture(_: GestureType, recognizer _: UIGestureRecognizer, touch _: UITouch) -> Bool {
            true
        }
    }
#endif
