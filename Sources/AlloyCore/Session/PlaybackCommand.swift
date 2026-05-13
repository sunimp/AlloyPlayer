//
//  PlaybackCommand.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import Foundation

/// 播放会话命令。
public enum PlaybackCommand: Equatable, Sendable {
    /// 加载播放源。
    case load(PlaybackSource)

    /// 开始或恢复播放。
    case play

    /// 暂停播放。
    case pause

    /// 停止播放。
    case stop

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
}
