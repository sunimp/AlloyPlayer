//
//  PlayerEvent.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/12.
//

import CoreGraphics
import Foundation

/// 播放器一次性事件。
public enum PlayerEvent: Equatable {
    case prepareToPlay(URL)
    case readyToPlay(URL)
    case playbackStateChanged(PlaybackState)
    case loadStateChanged(LoadState)
    case timeChanged(current: TimeInterval, total: TimeInterval)
    case bufferTimeChanged(TimeInterval)
    case failed(any Error)
    case playedToEnd
    case presentationSizeChanged(CGSize)
    case orientationWillChange(isFullScreen: Bool)
    case orientationDidChange(isFullScreen: Bool)

    public static func == (lhs: PlayerEvent, rhs: PlayerEvent) -> Bool {
        switch (lhs, rhs) {
        case let (.prepareToPlay(lhsURL), .prepareToPlay(rhsURL)):
            lhsURL == rhsURL
        case let (.readyToPlay(lhsURL), .readyToPlay(rhsURL)):
            lhsURL == rhsURL
        case let (.playbackStateChanged(lhsState), .playbackStateChanged(rhsState)):
            lhsState == rhsState
        case let (.loadStateChanged(lhsState), .loadStateChanged(rhsState)):
            lhsState == rhsState
        case let (.timeChanged(lhsCurrent, lhsTotal), .timeChanged(rhsCurrent, rhsTotal)):
            lhsCurrent == rhsCurrent && lhsTotal == rhsTotal
        case let (.bufferTimeChanged(lhsTime), .bufferTimeChanged(rhsTime)):
            lhsTime == rhsTime
        case (.playedToEnd, .playedToEnd):
            true
        case let (.presentationSizeChanged(lhsSize), .presentationSizeChanged(rhsSize)):
            lhsSize == rhsSize
        case let (.orientationWillChange(lhsFullScreen), .orientationWillChange(rhsFullScreen)):
            lhsFullScreen == rhsFullScreen
        case let (.orientationDidChange(lhsFullScreen), .orientationDidChange(rhsFullScreen)):
            lhsFullScreen == rhsFullScreen
        case (.failed, .failed):
            false
        default:
            false
        }
    }
}
