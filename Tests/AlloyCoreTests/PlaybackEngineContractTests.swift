//
//  PlaybackEngineContractTests.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

@testable import AlloyCore
import Combine
import Foundation
import Testing

@MainActor
@Suite("Playback Engine Contract Tests")
struct PlaybackEngineContractTests {
    @Test func fakeEngineUpdatesSnapshot() throws {
        let engine = FakePlaybackEngine()
        let source = try PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4")))

        #expect(engine.snapshot.playbackState == .idle)
        engine.load(source)
        #expect(engine.snapshot.source == source)
        engine.play()
        #expect(engine.snapshot.playbackState == .playing)
    }

    private final class FakePlaybackEngine: PlaybackEngine {
        private let snapshotSubject = CurrentValueSubject<PlaybackEngineSnapshot, Never>(PlaybackEngineSnapshot())
        private let eventSubject = PassthroughSubject<PlaybackEngineEvent, Never>()

        var snapshot: PlaybackEngineSnapshot {
            snapshotSubject.value
        }

        var snapshotPublisher: AnyPublisher<PlaybackEngineSnapshot, Never> {
            snapshotSubject.eraseToAnyPublisher()
        }

        var eventPublisher: AnyPublisher<PlaybackEngineEvent, Never> {
            eventSubject.eraseToAnyPublisher()
        }

        func load(_ source: PlaybackSource) {
            var next = snapshot
            next.source = source
            next.playbackState = .loading
            snapshotSubject.send(next)
            eventSubject.send(.didLoad(source))
        }

        func play() {
            var next = snapshot
            next.playbackState = .playing
            snapshotSubject.send(next)
        }

        func pause() {
            var next = snapshot
            next.playbackState = .paused
            snapshotSubject.send(next)
        }

        func stop() {
            var next = snapshot
            next.playbackState = .stopped
            snapshotSubject.send(next)
        }

        func seek(to time: TimeInterval) async -> Bool {
            eventSubject.send(.seekCompleted(time: time, finished: true))
            return true
        }

        func setRate(_ rate: Float) {
            var next = snapshot
            next.rate = rate
            snapshotSubject.send(next)
        }

        func setMuted(_ isMuted: Bool) {
            var next = snapshot
            next.isMuted = isMuted
            snapshotSubject.send(next)
        }

        func setVolume(_ volume: Float) {
            var next = snapshot
            next.volume = volume
            snapshotSubject.send(next)
        }

        func setScalingMode(_: ScalingMode) {}
    }
}
