//
//  PlaybackControlAction.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import Foundation

    /// 播放控制动作。
    public enum PlaybackControlAction: Equatable, Sendable {
        case play
        case pause
        case replay
        case seek(TimeInterval)
        case setRate(Float)
        case setMuted(Bool)
        case setVolume(Float)
        case setScalingMode(ScalingMode)
        case toggleFullscreen
    }
#endif
