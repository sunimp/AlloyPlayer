//
//  PlayerStateTests.swift
//  AlloyCoreTests
//
//  Created by Sun on 2026/5/12.
//

@testable import AlloyCore
import Combine
import Foundation
import Testing

@Test func playerStateDefaultValueRepresentsIdlePlayback() {
    let state = PlayerState()

    #expect(state.assetURL == nil)
    #expect(state.playbackState == .idle)
    #expect(state.loadState.isEmpty)
    #expect(state.currentTime == 0)
    #expect(state.totalTime == 0)
    #expect(state.bufferTime == 0)
    #expect(state.presentationSize == .zero)
    #expect(state.isFullScreen == false)
    #expect(state.isScreenLocked == false)
}

@Test func playerEventEquatableIgnoresErrorPayloadIdentityOnlyForNonErrorCases() throws {
    let url = try #require(URL(string: "https://example.invalid/video.mp4"))

    #expect(PlayerEvent.prepareToPlay(url) == .prepareToPlay(url))
    #expect(PlayerEvent.playbackStateChanged(.playing) == .playbackStateChanged(.playing))
    #expect(PlayerEvent.playedToEnd == .playedToEnd)
}

#if canImport(UIKit)
    import UIKit

    @MainActor
    @Test func playerStatePublisherEmitsLatestPlaybackFacts() throws {
        let engine = ObservablePlaybackEngine()
        let player = Player(engine: engine, containerView: UIView())
        let url = try #require(URL(string: "https://example.invalid/video.mp4"))
        var states: [PlayerState] = []
        let cancellable = player.statePublisher.sink { states.append($0) }

        player.assetURL = url
        engine.sendPlaybackState(.playing)
        engine.sendLoadState(.playable)
        engine.sendPlayTime(current: 12, total: 120)
        engine.sendBufferTime(30)
        engine.sendPresentationSize(CGSize(width: 1920, height: 1080))

        #expect(states.first?.playbackState == .idle)
        #expect(states.last?.assetURL == url)
        #expect(states.last?.playbackState == .playing)
        #expect(states.last?.loadState == .playable)
        #expect(states.last?.currentTime == 12)
        #expect(states.last?.totalTime == 120)
        #expect(states.last?.bufferTime == 30)
        #expect(states.last?.presentationSize == CGSize(width: 1920, height: 1080))
        _ = cancellable
    }

    @MainActor
    @Test func playerEventPublisherEmitsEdgeTriggeredPlaybackEvents() throws {
        let engine = ObservablePlaybackEngine()
        let player = Player(engine: engine, containerView: UIView())
        let url = try #require(URL(string: "https://example.invalid/video.mp4"))
        var events: [PlayerEvent] = []
        let cancellable = player.eventPublisher.sink { events.append($0) }

        player.assetURL = url
        engine.sendReadyToPlay(url)
        engine.sendPlaybackState(.playing)
        engine.sendDidPlayToEnd()

        #expect(events.contains(.prepareToPlay(url)))
        #expect(events.contains(.readyToPlay(url)))
        #expect(events.contains(.playbackStateChanged(.playing)))
        #expect(events.contains(.playedToEnd))
        _ = cancellable
    }

    @MainActor
    private final class ObservablePlaybackEngine: PlaybackEngine {
        let renderView = RenderView()
        var playbackState: PlaybackState = .idle
        var loadState: LoadState = []
        var isPlaying = false
        var isPreparedToPlay = true
        var volume: Float = 1
        var isMuted = false
        var rate: Float = 1
        var scalingMode: ScalingMode = .aspectFit
        var shouldAutoPlay = false
        var currentTime: TimeInterval = 0
        var totalTime: TimeInterval = 0
        var bufferTime: TimeInterval = 0
        var seekTime: TimeInterval = 0
        var assetURL: URL? {
            didSet {
                guard let assetURL, assetURL != oldValue else { return }
                prepareSubject.send(assetURL)
            }
        }

        var presentationSize: CGSize = .zero

        private let stateSubject = PassthroughSubject<PlaybackState, Never>()
        private let loadStateSubject = PassthroughSubject<LoadState, Never>()
        private let playTimeSubject = PassthroughSubject<(current: TimeInterval, total: TimeInterval), Never>()
        private let bufferTimeSubject = PassthroughSubject<TimeInterval, Never>()
        private let prepareSubject = PassthroughSubject<URL, Never>()
        private let readySubject = PassthroughSubject<URL, Never>()
        private let failedSubject = PassthroughSubject<any Error, Never>()
        private let endSubject = PassthroughSubject<Void, Never>()
        private let sizeSubject = PassthroughSubject<CGSize, Never>()

        var statePublisher: AnyPublisher<PlaybackState, Never> {
            stateSubject.eraseToAnyPublisher()
        }

        var loadStatePublisher: AnyPublisher<LoadState, Never> {
            loadStateSubject.eraseToAnyPublisher()
        }

        var playTimePublisher: AnyPublisher<(current: TimeInterval, total: TimeInterval), Never> {
            playTimeSubject.eraseToAnyPublisher()
        }

        var bufferTimePublisher: AnyPublisher<TimeInterval, Never> {
            bufferTimeSubject.eraseToAnyPublisher()
        }

        var prepareToPlayPublisher: AnyPublisher<URL, Never> {
            prepareSubject.eraseToAnyPublisher()
        }

        var readyToPlayPublisher: AnyPublisher<URL, Never> {
            readySubject.eraseToAnyPublisher()
        }

        var playFailedPublisher: AnyPublisher<any Error, Never> {
            failedSubject.eraseToAnyPublisher()
        }

        var didPlayToEndPublisher: AnyPublisher<Void, Never> {
            endSubject.eraseToAnyPublisher()
        }

        var presentationSizePublisher: AnyPublisher<CGSize, Never> {
            sizeSubject.eraseToAnyPublisher()
        }

        func prepareToPlay() {}
        func reloadPlayer() {}
        func play() {}
        func pause() {}
        func replay() {}
        func stop() {}
        func seek(to _: TimeInterval) async -> Bool {
            true
        }

        func sendPlaybackState(_ state: PlaybackState) {
            playbackState = state
            isPlaying = state == .playing
            stateSubject.send(state)
        }

        func sendLoadState(_ state: LoadState) {
            loadState = state
            loadStateSubject.send(state)
        }

        func sendPlayTime(current: TimeInterval, total: TimeInterval) {
            currentTime = current
            totalTime = total
            playTimeSubject.send((current: current, total: total))
        }

        func sendBufferTime(_ time: TimeInterval) {
            bufferTime = time
            bufferTimeSubject.send(time)
        }

        func sendReadyToPlay(_ url: URL) {
            readySubject.send(url)
        }

        func sendDidPlayToEnd() {
            endSubject.send()
        }

        func sendPresentationSize(_ size: CGSize) {
            presentationSize = size
            sizeSubject.send(size)
        }
    }
#endif
