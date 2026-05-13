//
//  PlaybackControlAction.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import Foundation

    /// 播放控制动作。
    public enum PlaybackControlAction: Equatable, Sendable {
        /// 开始或恢复播放。
        case play

        /// 暂停播放。
        case pause

        /// 重新播放当前资源。
        case replay

        /// 跳转到指定播放时间。
        case seek(TimeInterval)

        /// 设置播放速率。
        case setRate(Float)

        /// 设置静音状态。
        case setMuted(Bool)

        /// 设置音量。
        case setVolume(Float)

        /// 设置视频缩放模式。
        case setScalingMode(ScalingMode)

        /// 切换全屏状态。
        case toggleFullscreen
    }
#endif
