//
//  PlaybackEvent.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

/// 播放会话事件。
public enum PlaybackEvent: Equatable, Sendable {
    /// 来自播放引擎的事件。
    case engine(PlaybackEngineEvent)

    /// 播放命令已被会话接收并处理。
    case commandHandled(PlaybackCommand)
}
