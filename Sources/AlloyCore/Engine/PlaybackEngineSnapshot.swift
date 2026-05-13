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
    public var source: PlaybackSource?
    public var playbackState: PlaybackState
    public var loadState: LoadState
    public var currentTime: TimeInterval
    public var duration: TimeInterval
    public var bufferedTime: TimeInterval
    public var rate: Float
    public var volume: Float
    public var isMuted: Bool
    public var presentationSize: CGSize
    public var error: PlaybackError?

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
