//
//  PlaybackStateSnapshot.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

/// 播放会话状态快照。
public struct PlaybackStateSnapshot: Equatable, Sendable {
    /// 播放引擎状态快照。
    public var engine: PlaybackEngineSnapshot

    /// 用户是否主动暂停播放。
    public var isUserPaused: Bool

    /// 创建播放会话状态快照。
    public init(engine: PlaybackEngineSnapshot, isUserPaused: Bool = false) {
        self.engine = engine
        self.isUserPaused = isUserPaused
    }
}
