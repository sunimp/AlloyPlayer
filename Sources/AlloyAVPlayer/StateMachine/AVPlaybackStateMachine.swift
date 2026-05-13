//
//  AVPlaybackStateMachine.swift
//  AlloyAVPlayer
//
//  Created by Sun on 2026/5/13.
//

import AlloyCore
import Foundation

struct AVPlaybackStateMachine {
    enum State: Equatable {
        case idle
        case loading(PlaybackSource)
        case ready(PlaybackSource)
        case playing(PlaybackSource)
        case paused(PlaybackSource)
        case seeking(PlaybackSource, target: TimeInterval)
        case buffering(PlaybackSource)
        case ended(PlaybackSource)
        case failed(PlaybackSource?, PlaybackError)
        case stopped
    }

    enum Input: Equatable {
        case load(PlaybackSource)
        case itemReady
        case itemFailed(PlaybackError)
        case play
        case pause
        case seek(TimeInterval)
        case seekFinished(Bool)
        case bufferEmpty
        case likelyToKeepUp
        case playToEnd
        case stop
    }

    private(set) var state: State = .idle
    private var stateBeforeSeeking: State?

    @discardableResult
    mutating func apply(_ input: Input) -> State {
        switch input {
        case let .load(source):
            stateBeforeSeeking = nil
            state = .loading(source)

        case .stop:
            stateBeforeSeeking = nil
            state = .stopped

        case .itemReady:
            if let source {
                state = .ready(source)
            }

        case let .itemFailed(error):
            stateBeforeSeeking = nil
            state = .failed(source, error)

        case .play:
            if let source {
                state = .playing(source)
            }

        case .pause:
            if let source, case .playing = state {
                state = .paused(source)
            }

        case let .seek(time):
            if let source, state.canSeek {
                stateBeforeSeeking = state
                state = .seeking(source, target: time)
            }

        case let .seekFinished(finished):
            guard case let .seeking(source, _) = state else { break }
            if finished {
                state = stateBeforeSeeking?.stateAfterSuccessfulSeek(source: source) ?? .paused(source)
            } else {
                state = .failed(source, PlaybackError(code: .seekFailed, message: "seek failed"))
            }
            stateBeforeSeeking = nil

        case .bufferEmpty:
            if let source, case .playing = state {
                state = .buffering(source)
            }

        case .likelyToKeepUp:
            if let source, case .buffering = state {
                state = .playing(source)
            }

        case .playToEnd:
            if let source, case .playing = state {
                state = .ended(source)
            }
        }

        return state
    }

    private var source: PlaybackSource? {
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

private extension AVPlaybackStateMachine.State {
    var canSeek: Bool {
        switch self {
        case .ready, .playing, .paused, .buffering, .ended:
            true
        case .idle, .loading, .seeking, .failed, .stopped:
            false
        }
    }

    func stateAfterSuccessfulSeek(source: PlaybackSource) -> AVPlaybackStateMachine.State {
        switch self {
        case .playing, .buffering:
            .playing(source)
        case .ready:
            .ready(source)
        case .ended, .paused:
            .paused(source)
        case .idle, .loading, .seeking, .failed, .stopped:
            .paused(source)
        }
    }
}
