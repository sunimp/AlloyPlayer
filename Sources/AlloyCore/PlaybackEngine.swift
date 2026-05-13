//
//  PlaybackEngine.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Combine
import Foundation

/// 播放引擎协议。
@MainActor
public protocol PlaybackEngine: AnyObject {
    var snapshot: PlaybackEngineSnapshot { get }
    var snapshotPublisher: AnyPublisher<PlaybackEngineSnapshot, Never> { get }
    var eventPublisher: AnyPublisher<PlaybackEngineEvent, Never> { get }
    var renderSurface: PlaybackRenderSurface? { get }

    func load(_ source: PlaybackSource)
    func play()
    func pause()
    func stop()
    func seek(to time: TimeInterval) async -> Bool
    func setRate(_ rate: Float)
    func setMuted(_ isMuted: Bool)
    func setVolume(_ volume: Float)
    func setScalingMode(_ scalingMode: ScalingMode)
}

public extension PlaybackEngine {
    var snapshot: PlaybackEngineSnapshot {
        PlaybackEngineSnapshot()
    }

    var snapshotPublisher: AnyPublisher<PlaybackEngineSnapshot, Never> {
        Empty().eraseToAnyPublisher()
    }

    var eventPublisher: AnyPublisher<PlaybackEngineEvent, Never> {
        Empty().eraseToAnyPublisher()
    }

    var renderSurface: PlaybackRenderSurface? {
        nil
    }

    func load(_: PlaybackSource) {}
    func setRate(_: Float) {}
    func setMuted(_: Bool) {}
    func setVolume(_: Float) {}
    func setScalingMode(_: ScalingMode) {}
}
