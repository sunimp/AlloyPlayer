//
//  PlaybackSession.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import Combine
import Foundation

/// 播放会话。
@MainActor
public final class PlaybackSession {
    /// 会话绑定的播放引擎。
    public let engine: PlaybackEngine

    /// 播放会话配置。
    public var configuration: PlaybackSessionConfiguration

    /// 会话状态发布者。
    public var statePublisher: AnyPublisher<PlaybackStateSnapshot, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    /// 会话事件发布者。
    public var eventPublisher: AnyPublisher<PlaybackEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    /// 当前会话状态。
    public var state: PlaybackStateSnapshot {
        stateSubject.value
    }

    private let stateSubject: CurrentValueSubject<PlaybackStateSnapshot, Never>
    private let eventSubject = PassthroughSubject<PlaybackEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var isUserPaused = false

    /// 创建播放会话。
    public init(engine: PlaybackEngine, configuration: PlaybackSessionConfiguration = .init()) {
        self.engine = engine
        self.configuration = configuration
        stateSubject = CurrentValueSubject(PlaybackStateSnapshot(engine: engine.snapshot))
        bindEngine()
    }

    /// 发送播放命令。
    public func send(_ command: PlaybackCommand) {
        switch command {
        case let .load(source):
            load(source)
        case .play:
            play()
        case .pause:
            pause()
        case .stop:
            stop()
        case let .seek(time):
            Task { _ = await seek(to: time) }
        case let .setRate(rate):
            engine.setRate(rate)
            eventSubject.send(.commandHandled(command))
        case let .setMuted(isMuted):
            engine.setMuted(isMuted)
            eventSubject.send(.commandHandled(command))
        case let .setVolume(volume):
            engine.setVolume(volume)
            eventSubject.send(.commandHandled(command))
        case let .setScalingMode(scalingMode):
            engine.setScalingMode(scalingMode)
            eventSubject.send(.commandHandled(command))
        }
    }

    /// 加载播放源。
    public func load(_ source: PlaybackSource) {
        engine.load(source)
        eventSubject.send(.commandHandled(.load(source)))
    }

    /// 开始或恢复播放。
    public func play() {
        isUserPaused = false
        updateSessionState(engine: engine.snapshot)
        engine.play()
        eventSubject.send(.commandHandled(.play))
    }

    /// 暂停播放。
    public func pause() {
        isUserPaused = true
        updateSessionState(engine: engine.snapshot)
        engine.pause()
        eventSubject.send(.commandHandled(.pause))
    }

    /// 停止播放。
    public func stop() {
        engine.stop()
        eventSubject.send(.commandHandled(.stop))
    }

    /// 跳转到指定播放时间。
    @discardableResult
    public func seek(to time: TimeInterval) async -> Bool {
        let result = await engine.seek(to: time)
        eventSubject.send(.commandHandled(.seek(time)))
        return result
    }

    private func bindEngine() {
        engine.snapshotPublisher
            .sink { [weak self] snapshot in
                self?.updateSessionState(engine: snapshot)
            }
            .store(in: &cancellables)

        engine.eventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                self.eventSubject.send(.engine(event))
                self.handleEngineEvent(event)
            }
            .store(in: &cancellables)
    }

    private func handleEngineEvent(_ event: PlaybackEngineEvent) {
        guard case .readyToPlay = event,
              configuration.autoPlay,
              !isUserPaused
        else { return }
        play()
    }

    private func updateSessionState(engine snapshot: PlaybackEngineSnapshot) {
        stateSubject.send(PlaybackStateSnapshot(engine: snapshot, isUserPaused: isUserPaused))
    }
}
