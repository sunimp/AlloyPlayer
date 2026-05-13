//
//  PlaybackEvent.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

/// 播放会话事件。
public enum PlaybackEvent: Equatable, Sendable {
    case engine(PlaybackEngineEvent)
    case commandHandled(PlaybackCommand)
}
