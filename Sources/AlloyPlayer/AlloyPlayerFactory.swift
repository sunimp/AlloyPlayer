//
//  AlloyPlayerFactory.swift
//  AlloyPlayer
//
//  Created by Sun on 2026/5/13.
//

import AlloyAVPlayer
import AlloyCore

/// AlloyPlayer 默认对象工厂。
@MainActor
public enum AlloyPlayerFactory {
    /// 创建默认 AVFoundation 播放会话。
    public static func makeDefaultSession(
        configuration: PlaybackSessionConfiguration = .init(),
        engineConfiguration: AVPlaybackEngineConfiguration = .init()
    ) -> PlaybackSession {
        PlaybackSession(
            engine: AVPlaybackEngine(configuration: engineConfiguration),
            configuration: configuration
        )
    }
}
