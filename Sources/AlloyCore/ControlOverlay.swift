//
//  ControlOverlay.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    /// 播放器控制层协议
    ///
    /// 定义控制层 UI 与播放器之间的通信接口。
    /// 所有方法均有默认空实现，使用者只需实现关心的回调。
    /// 内置 UIKit 实现为 `DefaultControlOverlay`（AlloyUIKit 模块）。
    @MainActor
    public protocol ControlOverlay: UIView, PlaybackEventSink, GestureEventSink, OrientationEventSink {
        /// 关联的播放控制器
        var player: Player? { get set }

        // MARK: - 播放状态

        /// 准备播放
        func player(_ player: Player, prepareToPlay assetURL: URL)

        /// 播放状态变化
        func player(_ player: Player, didChangePlaybackState state: PlaybackState)

        /// 加载状态变化
        func player(_ player: Player, didChangeLoadState state: LoadState)

        // MARK: - 进度

        /// 播放时间更新
        func player(_ player: Player, didUpdateTime currentTime: TimeInterval, totalTime: TimeInterval)

        /// 缓冲时间更新
        func player(_ player: Player, didUpdateBufferTime bufferTime: TimeInterval)

        /// 拖动进度时调用
        func player(_ player: Player, draggingTime: TimeInterval, totalTime: TimeInterval)

        /// 播放完成
        func playerDidPlayToEnd(_ player: Player)

        /// 播放失败
        func player(_ player: Player, didFailWithError error: any Error)

        // MARK: - 锁屏

        /// 锁屏状态变化
        func player(_ player: Player, didChangeLockState isLocked: Bool)

        // MARK: - 旋转

        /// 即将旋转
        func player(_ player: Player, willChangeOrientation observer: OrientationManager)

        /// 旋转完成
        func player(_ player: Player, didChangeOrientation observer: OrientationManager)

        // MARK: - 网络

        /// 网络状态变化
        func player(_ player: Player, didChangeReachability status: ReachabilityStatus)

        // MARK: - 视频尺寸

        /// 视频尺寸变化
        func player(_ player: Player, didChangePresentationSize size: CGSize)

        // MARK: - 手势

        /// 手势触发条件判断
        func gestureTriggerCondition(
            _ gesture: GestureManager,
            type: GestureType,
            recognizer: UIGestureRecognizer,
            touch: UITouch
        ) -> Bool

        /// 单击
        func gestureSingleTapped(_ gesture: GestureManager)

        /// 双击
        func gestureDoubleTapped(_ gesture: GestureManager)

        /// 滑动开始
        func gestureBeganPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation)

        /// 滑动中
        func gestureChangedPan(
            _ gesture: GestureManager,
            direction: PanDirection,
            location: PanLocation,
            velocity: CGPoint
        )

        /// 滑动结束
        func gestureEndedPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation)

        /// 捏合缩放
        func gesturePinched(_ gesture: GestureManager, scale: Float)

        /// 长按
        func longPressed(_ gesture: GestureManager, state: LongPressPhase)
    }

    // MARK: - 默认空实现

    public extension ControlOverlay {
        func player(_: Player, prepareToPlay _: URL) {}
        func player(_: Player, didChangePlaybackState _: PlaybackState) {}
        func player(_: Player, didChangeLoadState _: LoadState) {}
        func player(_: Player, didUpdateTime _: TimeInterval, totalTime _: TimeInterval) {}
        func player(_: Player, didUpdateBufferTime _: TimeInterval) {}
        func player(_: Player, draggingTime _: TimeInterval, totalTime _: TimeInterval) {}
        func playerDidPlayToEnd(_: Player) {}
        func player(_: Player, didFailWithError _: any Error) {}
        func player(_: Player, didChangeLockState _: Bool) {}
        func player(_: Player, willChangeOrientation _: OrientationManager) {}
        func player(_: Player, didChangeOrientation _: OrientationManager) {}
        func player(_: Player, didChangeReachability _: ReachabilityStatus) {}
        func player(_: Player, didChangePresentationSize _: CGSize) {}
        func gestureTriggerCondition(_: GestureManager, type _: GestureType, recognizer _: UIGestureRecognizer, touch _: UITouch) -> Bool {
            true
        }

        func gestureSingleTapped(_: GestureManager) {}
        func gestureDoubleTapped(_: GestureManager) {}
        func gestureBeganPan(_: GestureManager, direction _: PanDirection, location _: PanLocation) {}
        func gestureChangedPan(_: GestureManager, direction _: PanDirection, location _: PanLocation, velocity _: CGPoint) {}
        func gestureEndedPan(_: GestureManager, direction _: PanDirection, location _: PanLocation) {}
        func gesturePinched(_: GestureManager, scale _: Float) {}
        func longPressed(_: GestureManager, state _: LongPressPhase) {}
    }
#endif
