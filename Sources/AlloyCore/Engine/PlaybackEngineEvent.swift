//
//  PlaybackEngineEvent.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import CoreGraphics
import Foundation

/// 播放引擎事件。
public enum PlaybackEngineEvent: Equatable, Sendable {
    case didLoad(PlaybackSource)
    case readyToPlay(PlaybackSource)
    case didPlayToEnd
    case failed(PlaybackError)
    case seekCompleted(time: TimeInterval, finished: Bool)
    case presentationSizeChanged(CGSize)
}
