//
//  PlayerState.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/12.
//

import CoreGraphics
import Foundation

/// 播放器当前可观察状态。
public struct PlayerState: Equatable {
    public var assetURL: URL?
    public var playbackState: PlaybackState
    public var loadState: LoadState
    public var currentTime: TimeInterval
    public var totalTime: TimeInterval
    public var bufferTime: TimeInterval
    public var presentationSize: CGSize
    public var isFullScreen: Bool
    public var isScreenLocked: Bool

    public init(
        assetURL: URL? = nil,
        playbackState: PlaybackState = .unknown,
        loadState: LoadState = .unknown,
        currentTime: TimeInterval = 0,
        totalTime: TimeInterval = 0,
        bufferTime: TimeInterval = 0,
        presentationSize: CGSize = .zero,
        isFullScreen: Bool = false,
        isScreenLocked: Bool = false
    ) {
        self.assetURL = assetURL
        self.playbackState = playbackState
        self.loadState = loadState
        self.currentTime = currentTime
        self.totalTime = totalTime
        self.bufferTime = bufferTime
        self.presentationSize = presentationSize
        self.isFullScreen = isFullScreen
        self.isScreenLocked = isScreenLocked
    }
}
