//
//  ListPlaybackCoordinatorTests.swift
//  AlloyListPlaybackTests
//
//  Created by Sun on 2026/5/12.
//

@testable import AlloyListPlayback
import Combine
import CoreGraphics
import Foundation
import Testing

#if canImport(UIKit)
    import AlloyCore
    import UIKit
#endif

@Test func listPlaybackCoordinatorSelectsMostVisibleCandidate() {
    let viewport = CGRect(x: 0, y: 0, width: 100, height: 100)
    let candidates = [
        ListPlaybackCandidate(indexPath: IndexPath(indexes: [0, 0]), frame: CGRect(x: 0, y: 80, width: 100, height: 100)),
        ListPlaybackCandidate(indexPath: IndexPath(indexes: [0, 1]), frame: CGRect(x: 0, y: 10, width: 100, height: 80)),
        ListPlaybackCandidate(indexPath: IndexPath(indexes: [0, 2]), frame: CGRect(x: 0, y: 120, width: 100, height: 80)),
    ]

    let selected = ListPlaybackCoordinator.selectCandidate(in: candidates, viewport: viewport)

    #expect(selected?.indexPath == IndexPath(indexes: [0, 1]))
}

@Test func listPlaybackCoordinatorIgnoresCandidatesBelowThreshold() {
    let viewport = CGRect(x: 0, y: 0, width: 100, height: 100)
    let candidates = [
        ListPlaybackCandidate(indexPath: IndexPath(indexes: [0, 0]), frame: CGRect(x: 0, y: 95, width: 100, height: 100)),
    ]

    let selected = ListPlaybackCoordinator.selectCandidate(in: candidates, viewport: viewport, minimumVisiblePercent: 0.1)

    #expect(selected == nil)
}

#if canImport(UIKit)
    @MainActor
    @Test func listPlaybackCoordinatorPlaysMostVisibleCandidate() throws {
        let engine = ListPlaybackMockEngine()
        let player = Player(engine: engine, containerView: UIView())
        let coordinator = ListPlaybackCoordinator(player: player)
        let firstURL = try #require(URL(string: "https://example.com/first.mp4"))
        let secondURL = try #require(URL(string: "https://example.com/second.mp4"))
        let viewport = CGRect(x: 0, y: 0, width: 100, height: 100)
        let candidates = [
            ListPlaybackCandidate(indexPath: IndexPath(indexes: [0, 0]), frame: CGRect(x: 0, y: 90, width: 100, height: 100), assetURL: firstURL),
            ListPlaybackCandidate(indexPath: IndexPath(indexes: [0, 1]), frame: CGRect(x: 0, y: 0, width: 100, height: 80), assetURL: secondURL),
        ]

        let selected = coordinator.playBestCandidate(
            in: candidates,
            viewport: viewport,
            minimumVisiblePercent: 0.5
        )

        #expect(selected?.indexPath == IndexPath(indexes: [0, 1]))
        #expect(player.playingIndexPath == IndexPath(indexes: [0, 1]))
        #expect(player.assetURL == secondURL)
    }

    @MainActor
    @Test func listPlaybackCoordinatorPlaysCandidateInExplicitContainer() throws {
        let engine = ListPlaybackMockEngine()
        let player = Player(engine: engine, containerView: UIView())
        let coordinator = ListPlaybackCoordinator(player: player)
        let containerView = UIView()
        let url = try #require(URL(string: "https://example.com/selected.mp4"))
        let candidate = ListPlaybackCandidate(
            indexPath: IndexPath(indexes: [0, 3]),
            frame: CGRect(x: 0, y: 0, width: 100, height: 100),
            assetURL: url
        )

        coordinator.play(candidate, in: containerView)

        #expect(player.playingIndexPath == IndexPath(indexes: [0, 3]))
        #expect(player.assetURL == url)
        #expect(engine.renderSurface.view.superview === containerView)
    }

    @MainActor
    @Test func listPlaybackCoordinatorPlaysBestCandidateWithContainerProvider() throws {
        let engine = ListPlaybackMockEngine()
        let player = Player(engine: engine, containerView: UIView())
        let coordinator = ListPlaybackCoordinator(player: player)
        let selectedContainer = UIView()
        let selectedURL = try #require(URL(string: "https://example.com/best.mp4"))
        let viewport = CGRect(x: 0, y: 0, width: 100, height: 100)
        let candidates = [
            ListPlaybackCandidate(indexPath: IndexPath(indexes: [0, 0]), frame: CGRect(x: 0, y: 90, width: 100, height: 100)),
            ListPlaybackCandidate(indexPath: IndexPath(indexes: [0, 1]), frame: CGRect(x: 0, y: 0, width: 100, height: 80), assetURL: selectedURL),
        ]

        let selected = coordinator.playBestCandidate(
            in: candidates,
            viewport: viewport,
            minimumVisiblePercent: 0.5,
            containerProvider: { candidate in
                candidate.indexPath == IndexPath(indexes: [0, 1]) ? selectedContainer : nil
            }
        )

        #expect(selected?.indexPath == IndexPath(indexes: [0, 1]))
        #expect(player.assetURL == selectedURL)
        #expect(engine.renderSurface.view.superview === selectedContainer)
    }

    @MainActor
    private final class ListPlaybackMockEngine: PlaybackEngine {
        let renderView = RenderView()
        var playbackState: PlaybackState = .unknown
        var loadState: LoadState = .unknown
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
        var assetURL: URL?
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
    }
#endif
