//
//  AVPlaybackEngineConfiguration.swift
//  AlloyAVPlayer
//
//  Created by Sun on 2026/5/13.
//

import Foundation

/// AVFoundation 播放引擎配置。
public struct AVPlaybackEngineConfiguration: Equatable, Sendable {
    public var timeRefreshInterval: TimeInterval
    public var automaticallyWaitsToMinimizeStalling: Bool

    public init(
        timeRefreshInterval: TimeInterval = 0.1,
        automaticallyWaitsToMinimizeStalling: Bool = false
    ) {
        self.timeRefreshInterval = timeRefreshInterval
        self.automaticallyWaitsToMinimizeStalling = automaticallyWaitsToMinimizeStalling
    }
}
