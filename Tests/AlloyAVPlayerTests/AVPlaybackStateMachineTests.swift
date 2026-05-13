//
//  AVPlaybackStateMachineTests.swift
//  AlloyAVPlayer
//
//  Created by Sun on 2026/5/13.
//

@testable import AlloyAVPlayer
import AlloyCore
import Foundation
import Testing

@Suite("AV Playback State Machine Tests")
struct AVPlaybackStateMachineTests {
    @Test func loadAndReadyTransitions() throws {
        var machine = AVPlaybackStateMachine()
        let source = try makeSource()

        #expect(machine.apply(.load(source)) == .loading(source))
        #expect(machine.apply(.itemReady) == .ready(source))
        #expect(machine.apply(.play) == .playing(source))
    }

    @Test func pauseAndSeekTransitions() throws {
        var machine = try readyPlayingMachine(source: makeSource())
        let source = try #require(machine.currentSource)

        #expect(machine.apply(.pause) == .paused(source))
        #expect(machine.apply(.play) == .playing(source))
        #expect(machine.apply(.seek(12)) == .seeking(source, target: 12))
        #expect(machine.apply(.seekFinished(true)) == .playing(source))
    }

    @Test func seekFromPausedReturnsToPaused() throws {
        var machine = try readyPlayingMachine(source: makeSource())
        let source = try #require(machine.currentSource)

        #expect(machine.apply(.pause) == .paused(source))
        #expect(machine.apply(.seek(12)) == .seeking(source, target: 12))
        #expect(machine.apply(.seekFinished(true)) == .paused(source))
    }

    @Test func failedSeekTransitionsToFailed() throws {
        var machine = try readyPlayingMachine(source: makeSource())
        let source = try #require(machine.currentSource)

        #expect(machine.apply(.seek(8)) == .seeking(source, target: 8))
        #expect(machine.apply(.seekFinished(false)) == .failed(source, PlaybackError(code: .seekFailed, message: "seek failed")))
    }

    @Test func bufferingTransitions() throws {
        var machine = try readyPlayingMachine(source: makeSource())
        let source = try #require(machine.currentSource)

        #expect(machine.apply(.bufferEmpty) == .buffering(source))
        #expect(machine.apply(.likelyToKeepUp) == .playing(source))
    }

    @Test func seekFromBufferingKeepsPlaybackIntent() throws {
        var machine = try readyPlayingMachine(source: makeSource())
        let source = try #require(machine.currentSource)

        #expect(machine.apply(.bufferEmpty) == .buffering(source))
        #expect(machine.apply(.seek(30)) == .seeking(source, target: 30))
        #expect(machine.apply(.seekFinished(true)) == .playing(source))
    }

    @Test func playToEndTransitions() throws {
        var machine = try readyPlayingMachine(source: makeSource())
        let source = try #require(machine.currentSource)

        #expect(machine.apply(.playToEnd) == .ended(source))
    }

    @Test func stopAndReloadTransitions() throws {
        var machine = try readyPlayingMachine(source: makeSource())
        let newSource = try PlaybackSource(url: #require(URL(string: "https://example.com/next.mp4")))

        #expect(machine.apply(.stop) == .stopped)
        #expect(machine.apply(.load(newSource)) == .loading(newSource))
    }

    @Test func itemFailedTransitionsFromLoading() throws {
        var machine = AVPlaybackStateMachine()
        let source = try makeSource()
        let error = PlaybackError(code: .engineFailed, message: "failed")

        _ = machine.apply(.load(source))

        #expect(machine.apply(.itemFailed(error)) == .failed(source, error))
    }

    private func makeSource() throws -> PlaybackSource {
        try PlaybackSource(url: #require(URL(string: "https://example.com/video.mp4")))
    }

    private func readyPlayingMachine(source: PlaybackSource) -> AVPlaybackStateMachine {
        var machine = AVPlaybackStateMachine()
        _ = machine.apply(.load(source))
        _ = machine.apply(.itemReady)
        _ = machine.apply(.play)
        return machine
    }
}

private extension AVPlaybackStateMachine {
    var currentSource: PlaybackSource? {
        switch state {
        case let .loading(source),
             let .ready(source),
             let .playing(source),
             let .paused(source),
             let .seeking(source, _),
             let .buffering(source),
             let .ended(source):
            source
        case let .failed(source, _):
            source
        case .idle, .stopped:
            nil
        }
    }
}
