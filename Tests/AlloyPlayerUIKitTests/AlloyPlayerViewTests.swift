//
//  AlloyPlayerViewTests.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    @testable import AlloyPlayerUIKit
    import Combine
    import Foundation
    import Testing
    import UIKit

    @MainActor
    @Suite("Alloy Player View Tests")
    struct AlloyPlayerViewTests {
        @Test func convenienceInitializerCreatesDefaultSessionAndOverlay() throws {
            let source = try PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4")))
            let playerView = AlloyPlayerView(source: source)

            #expect(playerView.session.state.engine.source == source)
            #expect(playerView.controlOverlay != nil)
        }

        @Test func loadForwardsToSessionEngine() throws {
            let engine = ViewTestEngine()
            let session = PlaybackSession(engine: engine)
            let playerView = AlloyPlayerView(session: session)
            let source = try PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4")))

            playerView.load(source)

            #expect(engine.loadedSource == source)
        }

        @Test func landscapeFullscreenContextWaitsForLandscapeGeometry() {
            let session = PlaybackSession(engine: ViewTestEngine())
            let playerView = AlloyPlayerView(session: session)
            let overlay = CapturingOverlay()
            let fullscreenCoordinator = StubFullscreenCoordinator(state: .fullscreen, fullscreenMode: .landscape)
            playerView.frame = CGRect(x: 0, y: 0, width: 390, height: 844)

            playerView.fullscreenCoordinator = fullscreenCoordinator
            playerView.controlOverlay = overlay
            playerView.layoutIfNeeded()

            #expect(overlay.latestContext?.layout == .fullscreenPortrait)

            playerView.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
            playerView.layoutIfNeeded()

            #expect(overlay.latestContext?.layout == .fullscreenLandscape)
        }

        @Test func stoppedPlaybackExitsFullscreenByDefault() async {
            let engine = ViewTestEngine()
            let session = PlaybackSession(engine: engine)
            let playerView = AlloyPlayerView(session: session)
            let fullscreenCoordinator = StubFullscreenCoordinator(state: .fullscreen, fullscreenMode: .landscape)
            playerView.fullscreenCoordinator = fullscreenCoordinator

            playerView.stop()
            await Task.yield()

            #expect(fullscreenCoordinator.state == .inline)
            #expect(fullscreenCoordinator.setFullscreenCalls == [false])
        }

        @Test func endedPlaybackExitsFullscreenByDefault() async {
            let engine = ViewTestEngine()
            let session = PlaybackSession(engine: engine)
            let playerView = AlloyPlayerView(session: session)
            let fullscreenCoordinator = StubFullscreenCoordinator(state: .fullscreen, fullscreenMode: .landscape)
            playerView.fullscreenCoordinator = fullscreenCoordinator

            engine.sendPlaybackState(.ended)
            await Task.yield()

            #expect(fullscreenCoordinator.state == .inline)
            #expect(fullscreenCoordinator.setFullscreenCalls == [false])
        }

        @Test func stoppedPlaybackCanKeepFullscreenWhenConfigured() async {
            let engine = ViewTestEngine()
            let session = PlaybackSession(engine: engine)
            let playerView = AlloyPlayerView(
                session: session,
                configuration: AlloyPlayerViewConfiguration(exitsFullscreenWhenStopped: false)
            )
            let fullscreenCoordinator = StubFullscreenCoordinator(state: .fullscreen, fullscreenMode: .landscape)
            playerView.fullscreenCoordinator = fullscreenCoordinator

            playerView.stop()
            await Task.yield()

            #expect(fullscreenCoordinator.state == .fullscreen)
            #expect(fullscreenCoordinator.setFullscreenCalls.isEmpty)
        }

        @Test func endedPlaybackCanKeepFullscreenWhenConfigured() async {
            let engine = ViewTestEngine()
            let session = PlaybackSession(engine: engine)
            let playerView = AlloyPlayerView(
                session: session,
                configuration: AlloyPlayerViewConfiguration(exitsFullscreenWhenStopped: false)
            )
            let fullscreenCoordinator = StubFullscreenCoordinator(state: .fullscreen, fullscreenMode: .landscape)
            playerView.fullscreenCoordinator = fullscreenCoordinator

            engine.sendPlaybackState(.ended)
            await Task.yield()

            #expect(fullscreenCoordinator.state == .fullscreen)
            #expect(fullscreenCoordinator.setFullscreenCalls.isEmpty)
        }

        @Test func enablingExitFullscreenAfterStoppedPlaybackExitsCurrentFullscreen() async {
            let engine = ViewTestEngine()
            let session = PlaybackSession(engine: engine)
            let playerView = AlloyPlayerView(
                session: session,
                configuration: AlloyPlayerViewConfiguration(exitsFullscreenWhenStopped: false)
            )
            let fullscreenCoordinator = StubFullscreenCoordinator(state: .fullscreen, fullscreenMode: .landscape)
            playerView.fullscreenCoordinator = fullscreenCoordinator

            playerView.stop()
            await Task.yield()
            playerView.configuration.exitsFullscreenWhenStopped = true
            await Task.yield()

            #expect(fullscreenCoordinator.state == .inline)
            #expect(fullscreenCoordinator.setFullscreenCalls == [false])
        }

        private final class CapturingOverlay: UIView, UIKitControlOverlay {
            var actionHandler: ((PlaybackControlAction) -> Void)?
            var latestContext: PlaybackControlContext?

            func render(context: PlaybackControlContext) {
                latestContext = context
            }
        }

        private final class StubFullscreenCoordinator: FullscreenCoordinating {
            private(set) var state: FullscreenState
            let fullscreenMode: FullscreenMode
            private(set) var setFullscreenCalls: [Bool] = []
            private let subject: CurrentValueSubject<FullscreenState, Never>

            var statePublisher: AnyPublisher<FullscreenState, Never> {
                subject.eraseToAnyPublisher()
            }

            init(state: FullscreenState, fullscreenMode: FullscreenMode) {
                self.state = state
                self.fullscreenMode = fullscreenMode
                subject = CurrentValueSubject(state)
            }

            func setFullscreen(_ isFullscreen: Bool, animated _: Bool) async {
                setFullscreenCalls.append(isFullscreen)
                state = isFullscreen ? .fullscreen : .inline
                subject.send(state)
            }

            func toggle(animated _: Bool) async {}
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
            func stop() {
                sendPlaybackState(.stopped)
            }

            func sendPlaybackState(_ playbackState: PlaybackState) {
                var snapshot = self.snapshot
                snapshot.playbackState = playbackState
                snapshotSubject.send(snapshot)
            }

            func seek(to _: TimeInterval) async -> Bool {
                true
            }
        }
    }
#endif
