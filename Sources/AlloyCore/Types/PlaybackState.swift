//
//  PlaybackState.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

/// 播放状态。
public enum PlaybackState: Equatable, Sendable {
    case idle
    case loading
    case ready
    case playing
    case paused
    case seeking
    case buffering
    case ended
    case failed
    case stopped
}
