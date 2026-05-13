//
//  AVPlaybackEngineConfiguration.swift
//  AlloyAVPlayer
//
//  Created by Sun on 2026/5/13.
//

import Foundation

/// AVFoundation 播放引擎配置。
public struct AVPlaybackEngineConfiguration: Equatable, Sendable {
    /// 播放时间刷新间隔，单位为秒。
    public var timeRefreshInterval: TimeInterval

    /// 是否启用 AVPlayer 的自动等待以尽量减少卡顿。
    public var automaticallyWaitsToMinimizeStalling: Bool

    /// 创建 AVFoundation 播放引擎配置。
    public init(
        timeRefreshInterval: TimeInterval = 0.1,
        automaticallyWaitsToMinimizeStalling: Bool = false
    ) {
        self.timeRefreshInterval = timeRefreshInterval
        self.automaticallyWaitsToMinimizeStalling = automaticallyWaitsToMinimizeStalling
    }
}
