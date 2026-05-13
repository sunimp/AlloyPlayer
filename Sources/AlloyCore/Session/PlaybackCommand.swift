//
//  PlaybackCommand.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import Foundation

/// 播放会话命令。
public enum PlaybackCommand: Equatable, Sendable {
    case load(PlaybackSource)
    case play
    case pause
    case stop
    case seek(TimeInterval)
    case setRate(Float)
    case setMuted(Bool)
    case setVolume(Float)
    case setScalingMode(ScalingMode)
}
