//
//  PlaybackState.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

/// 播放状态。
public enum PlaybackState: Equatable, Sendable {
    /// 尚未加载播放源。
    case idle

    /// 正在加载播放源。
    case loading

    /// 已准备好播放。
    case ready

    /// 正在播放。
    case playing

    /// 已暂停。
    case paused

    /// 正在跳转。
    case seeking

    /// 正在缓冲。
    case buffering

    /// 已播放至结尾。
    case ended

    /// 播放失败。
    case failed

    /// 已停止播放。
    case stopped
}
