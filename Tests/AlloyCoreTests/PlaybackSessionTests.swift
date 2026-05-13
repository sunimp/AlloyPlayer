//
//  PlaybackSessionTests.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

@testable import AlloyCore
import Combine
import Foundation
import Testing

@MainActor
@Suite("Playback Session Tests")
struct PlaybackSessionTests {
    @Test func loadForwardsSourceToEngine() throws {
        let engine = SessionTestEngine()
        let session = PlaybackSession(engine: engine)
        let source = try PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4")))

        session.load(source)

        #expect(engine.loadedSource == source)
        #expect(session.state.engine.source == source)
    }

    @Test func pauseMarksUserPaused() {
        let engine = SessionTestEngine()
        let session = PlaybackSession(engine: engine)

        session.pause()

        #expect(session.state.isUserPaused)
        #expect(engine.pauseCount == 1)
    }

    @Test func playClearsUserPaused() {
        let engine = SessionTestEngine()
        let session = PlaybackSession(engine: engine)

        session.pause()
        session.play()

        #expect(!session.state.isUserPaused)
        #expect(engine.playCount == 1)
    }

    @Test func engineEventsAreReemittedAsSessionEvents() throws {
        let engine = SessionTestEngine()
        let session = PlaybackSession(engine: engine, configuration: .init(autoPlay: false))
        let source = try PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4")))
        var events: [PlaybackEvent] = []
        let cancellable = session.eventPublisher.sink { events.append($0) }

        engine.sendEvent(.readyToPlay(source))

        #expect(events.contains(.engine(.readyToPlay(source))))
        _ = cancellable
    }

    @Test func seekReturnsEngineResult() async {
        let engine = SessionTestEngine()
        let session = PlaybackSession(engine: engine)
        engine.seekResult = false

        let result = await session.seek(to: 12)

        #expect(result == false)
        #expect(engine.seekTimes == [12])
    }

    private final class SessionTestEngine: PlaybackEngine {
        private let snapshotSubject = CurrentValueSubject<PlaybackEngineSnapshot, Never>(PlaybackEngineSnapshot())
        private let eventSubject = PassthroughSubject<PlaybackEngineEvent, Never>()

        var loadedSource: PlaybackSource?
        var playCount = 0
        var pauseCount = 0
        var stopCount = 0
        var seekTimes: [TimeInterval] = []
        var seekResult = true

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
            loadedSource = source
            var snapshot = self.snapshot
            snapshot.source = source
            snapshot.playbackState = .loading
            snapshotSubject.send(snapshot)
        }

        func play() {
            playCount += 1
            var snapshot = self.snapshot
            snapshot.playbackState = .playing
            snapshotSubject.send(snapshot)
        }

        func pause() {
            pauseCount += 1
            var snapshot = self.snapshot
            snapshot.playbackState = .paused
            snapshotSubject.send(snapshot)
        }

        func stop() {
            stopCount += 1
            var snapshot = self.snapshot
            snapshot.playbackState = .stopped
            snapshotSubject.send(snapshot)
        }

        func seek(to time: TimeInterval) async -> Bool {
            seekTimes.append(time)
            return seekResult
        }

        func setRate(_ rate: Float) {
            var snapshot = self.snapshot
            snapshot.rate = rate
            snapshotSubject.send(snapshot)
        }

        func setMuted(_ isMuted: Bool) {
            var snapshot = self.snapshot
            snapshot.isMuted = isMuted
            snapshotSubject.send(snapshot)
        }

        func setVolume(_ volume: Float) {
            var snapshot = self.snapshot
            snapshot.volume = volume
            snapshotSubject.send(snapshot)
        }

        func setScalingMode(_: ScalingMode) {}

        func sendEvent(_ event: PlaybackEngineEvent) {
            eventSubject.send(event)
        }
    }
}
