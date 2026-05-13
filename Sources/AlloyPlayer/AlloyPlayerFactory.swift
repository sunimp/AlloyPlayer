//
//  AlloyPlayerFactory.swift
//  AlloyPlayer
//
//  Created by Sun on 2026/5/13.
//

import AlloyAVPlayer
import AlloyCore

@MainActor
public enum AlloyPlayerFactory {
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
