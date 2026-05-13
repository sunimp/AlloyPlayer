//
//  AlloyPlayerViewTests.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    @testable import AlloyUIKit
    import Combine
    import Foundation
    import Testing
    import UIKit

    @MainActor
    @Suite("Alloy Player View Tests")
    struct AlloyPlayerViewTests {
        @Test func loadForwardsToSessionEngine() throws {
            let engine = ViewTestEngine()
            let session = PlaybackSession(engine: engine)
            let playerView = AlloyPlayerView(session: session)
            let source = try PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4")))

            playerView.load(source)

            #expect(engine.loadedSource == source)
        }

        private final class ViewTestEngine: PlaybackEngine {
            private let snapshotSubject = CurrentValueSubject<PlaybackEngineSnapshot, Never>(PlaybackEngineSnapshot())
            private let eventSubject = PassthroughSubject<PlaybackEngineEvent, Never>()
            var loadedSource: PlaybackSource?

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

            func play() {}
            func pause() {}
            func stop() {}
            func seek(to _: TimeInterval) async -> Bool {
                true
            }
        }
    }
#endif
