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
    /// 当前播放引擎状态快照。
    var snapshot: PlaybackEngineSnapshot { get }

    /// 播放引擎状态快照发布者。
    var snapshotPublisher: AnyPublisher<PlaybackEngineSnapshot, Never> { get }

    /// 播放引擎事件发布者。
    var eventPublisher: AnyPublisher<PlaybackEngineEvent, Never> { get }

    /// 当前播放源对应的渲染承载面。
    var renderSurface: PlaybackRenderSurface? { get }

    /// 加载播放源。
    func load(_ source: PlaybackSource)

    /// 开始或恢复播放。
    func play()

    /// 暂停播放。
    func pause()

    /// 停止播放并释放当前资源。
    func stop()

    /// 跳转到指定播放时间。
    func seek(to time: TimeInterval) async -> Bool

    /// 设置播放速率。
    func setRate(_ rate: Float)

    /// 设置静音状态。
    func setMuted(_ isMuted: Bool)

    /// 设置音量。
    func setVolume(_ volume: Float)

    /// 设置视频缩放模式。
    func setScalingMode(_ scalingMode: ScalingMode)
}

/// 播放引擎默认实现。
public extension PlaybackEngine {
    /// 默认状态快照。
    var snapshot: PlaybackEngineSnapshot {
        PlaybackEngineSnapshot()
    }

    /// 默认状态发布者，不发送任何快照。
    var snapshotPublisher: AnyPublisher<PlaybackEngineSnapshot, Never> {
        Empty().eraseToAnyPublisher()
    }

    /// 默认事件发布者，不发送任何事件。
    var eventPublisher: AnyPublisher<PlaybackEngineEvent, Never> {
        Empty().eraseToAnyPublisher()
    }

    /// 默认渲染承载面。
    var renderSurface: PlaybackRenderSurface? {
        nil
    }

    /// 默认加载实现。
    func load(_: PlaybackSource) {}

    /// 默认播放速率设置实现。
    func setRate(_: Float) {}

    /// 默认静音设置实现。
    func setMuted(_: Bool) {}

    /// 默认音量设置实现。
    func setVolume(_: Float) {}

    /// 默认视频缩放模式设置实现。
    func setScalingMode(_: ScalingMode) {}
}
