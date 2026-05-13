//
//  PlaybackStateSnapshot.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

/// 播放会话状态快照。
public struct PlaybackStateSnapshot: Equatable, Sendable {
    public var engine: PlaybackEngineSnapshot
    public var isUserPaused: Bool

    public init(engine: PlaybackEngineSnapshot, isUserPaused: Bool = false) {
        self.engine = engine
        self.isUserPaused = isUserPaused
    }
}
