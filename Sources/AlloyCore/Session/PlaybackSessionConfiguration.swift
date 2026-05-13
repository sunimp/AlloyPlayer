//
//  PlaybackSessionConfiguration.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import Foundation

/// 播放会话配置。
public struct PlaybackSessionConfiguration: Equatable, Sendable {
    public var autoPlay: Bool
    public var startTime: TimeInterval

    public init(autoPlay: Bool = true, startTime: TimeInterval = 0) {
        self.autoPlay = autoPlay
        self.startTime = startTime
    }
}
