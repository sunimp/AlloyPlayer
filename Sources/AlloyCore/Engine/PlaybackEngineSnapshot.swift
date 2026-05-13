//
//  PlaybackEngineSnapshot.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import CoreGraphics
import Foundation

/// 播放引擎状态快照。
public struct PlaybackEngineSnapshot: Equatable, Sendable {
    /// 当前播放源。
    public var source: PlaybackSource?

    /// 当前播放状态。
    public var playbackState: PlaybackState

    /// 当前加载状态集合。
    public var loadState: LoadState

    /// 当前播放时间，单位为秒。
    public var currentTime: TimeInterval

    /// 媒体总时长，单位为秒。
    public var duration: TimeInterval

    /// 已缓冲到的时间点，单位为秒。
    public var bufferedTime: TimeInterval

    /// 当前播放速率。
    public var rate: Float

    /// 当前音量，取值范围由具体引擎定义。
    public var volume: Float

    /// 当前是否静音。
    public var isMuted: Bool

    /// 视频原始展示尺寸。
    public var presentationSize: CGSize

    /// 最近一次播放错误。
    public var error: PlaybackError?

    /// 创建播放引擎状态快照。
    public init(
        source: PlaybackSource? = nil,
        playbackState: PlaybackState = .idle,
        loadState: LoadState = [],
        currentTime: TimeInterval = 0,
        duration: TimeInterval = 0,
        bufferedTime: TimeInterval = 0,
        rate: Float = 1,
        volume: Float = 1,
        isMuted: Bool = false,
        presentationSize: CGSize = .zero,
        error: PlaybackError? = nil
    ) {
        self.source = source
        self.playbackState = playbackState
        self.loadState = loadState
        self.currentTime = currentTime
        self.duration = duration
        self.bufferedTime = bufferedTime
        self.rate = rate
        self.volume = volume
        self.isMuted = isMuted
        self.presentationSize = presentationSize
        self.error = error
    }
}
