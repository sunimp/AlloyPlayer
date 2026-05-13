//
//  AlloyPlayerControllerTests.swift
//  AlloyPlayerSwiftUITests
//
//  Created by Sun on 2026/5/13.
//

#if canImport(SwiftUI)
    import AlloyCore
    @testable import AlloyPlayerSwiftUI
    import Combine
    import Foundation
    import Testing

    @MainActor
    @Suite("Alloy Player Controller Tests")
    struct AlloyPlayerControllerTests {
        @Test func convenienceInitializerCreatesDefaultSessionAndLoadsSource() throws {
            let source = try PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4")))
            let controller = AlloyPlayerController(source: source)

            #expect(controller.state.engine.source == source)
        }

        @Test func controllerReflectsSessionStateAndForwardsCommands() throws {
            let engine = ControllerTestEngine()
            let controller = AlloyPlayerController(session: PlaybackSession(engine: engine, configuration: .init(autoPlay: false)))
            let source = try PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4")))

            controller.load(source)
            controller.play()
            controller.pause()

            #expect(engine.loadedSource == source)
            #expect(engine.playCount == 1)
            #expect(engine.pauseCount == 1)
            #expect(controller.state.engine.source == source)
        }

        @Test func seekReturnsEngineResult() async {
            let engine = ControllerTestEngine()
            engine.seekResult = false
            let controller = AlloyPlayerController(session: PlaybackSession(engine: engine))

            let result = await controller.seek(to: 8)

            #expect(result == false)
            #expect(engine.seekTimes == [8])
        }

        private final class ControllerTestEngine: PlaybackEngine {
            private let snapshotSubject = CurrentValueSubject<PlaybackEngineSnapshot, Never>(PlaybackEngineSnapshot())
            private let eventSubject = PassthroughSubject<PlaybackEngineEvent, Never>()
            var loadedSource: PlaybackSource?
            var playCount = 0
            var pauseCount = 0
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

            func stop() {}

            func seek(to time: TimeInterval) async -> Bool {
                seekTimes.append(time)
                return seekResult
            }
        }
    }
#endif
