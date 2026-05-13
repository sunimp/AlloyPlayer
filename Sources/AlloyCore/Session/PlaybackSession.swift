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
    public let engine: PlaybackEngine
    public var configuration: PlaybackSessionConfiguration

    public var statePublisher: AnyPublisher<PlaybackStateSnapshot, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public var eventPublisher: AnyPublisher<PlaybackEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    public var state: PlaybackStateSnapshot {
        stateSubject.value
    }

    private let stateSubject: CurrentValueSubject<PlaybackStateSnapshot, Never>
    private let eventSubject = PassthroughSubject<PlaybackEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var isUserPaused = false

    public init(engine: PlaybackEngine, configuration: PlaybackSessionConfiguration = .init()) {
        self.engine = engine
        self.configuration = configuration
        stateSubject = CurrentValueSubject(PlaybackStateSnapshot(engine: engine.snapshot))
        bindEngine()
    }

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

    public func load(_ source: PlaybackSource) {
        engine.load(source)
        eventSubject.send(.commandHandled(.load(source)))
    }

    public func play() {
        isUserPaused = false
        updateSessionState(engine: engine.snapshot)
        engine.play()
        eventSubject.send(.commandHandled(.play))
    }

    public func pause() {
        isUserPaused = true
        updateSessionState(engine: engine.snapshot)
        engine.pause()
        eventSubject.send(.commandHandled(.pause))
    }

    public func stop() {
        engine.stop()
        eventSubject.send(.commandHandled(.stop))
    }

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
