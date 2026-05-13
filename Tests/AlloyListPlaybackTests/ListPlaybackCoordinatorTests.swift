//
//  ListPlaybackCoordinatorTests.swift
//  AlloyListPlaybackTests
//
//  Created by Sun on 2026/5/13.
//

import AlloyCore
@testable import AlloyListPlayback
import Combine
import CoreGraphics
import Foundation
import Testing

@Test func listPlaybackCoordinatorSelectsMostVisibleCandidate() throws {
    let viewport = CGRect(x: 0, y: 0, width: 100, height: 100)
    let source = try PlaybackSource(url: #require(URL(string: "https://example.com/video.mp4")))
    let candidates = [
        ListPlaybackCandidate(id: "0", frame: CGRect(x: 0, y: 80, width: 100, height: 100), source: source),
        ListPlaybackCandidate(id: "1", frame: CGRect(x: 0, y: 10, width: 100, height: 80), source: source),
        ListPlaybackCandidate(id: "2", frame: CGRect(x: 0, y: 120, width: 100, height: 80), source: source),
    ]

    let selected = ListPlaybackCoordinator.selectCandidate(in: candidates, viewport: viewport)

    #expect(selected?.id == "1")
}

@Test func listPlaybackCoordinatorIgnoresCandidatesBelowThreshold() throws {
    let viewport = CGRect(x: 0, y: 0, width: 100, height: 100)
    let source = try PlaybackSource(url: #require(URL(string: "https://example.com/video.mp4")))
    let candidates = [
        ListPlaybackCandidate(id: "0", frame: CGRect(x: 0, y: 95, width: 100, height: 100), source: source),
    ]

    let selected = ListPlaybackCoordinator.selectCandidate(in: candidates, viewport: viewport, minimumVisiblePercent: 0.1)

    #expect(selected == nil)
}

#if canImport(UIKit)
    import AlloyPlayerUIKit
    import UIKit

    @MainActor
    @Test func listPlaybackCoordinatorLoadsSelectedCandidateInContainer() throws {
        let engine = ListPlaybackMockEngine()
        let session = PlaybackSession(engine: engine)
        let renderView = AlloyPlayerUIKit.AlloyPlayerRenderView(session: session)
        let coordinator = ListPlaybackCoordinator(session: session, renderView: renderView)
        let container = UIView()
        let source = try PlaybackSource(url: #require(URL(string: "https://example.com/best.mp4")))
        let viewport = CGRect(x: 0, y: 0, width: 100, height: 100)
        let candidates = [
            ListPlaybackCandidate(id: "low", frame: CGRect(x: 0, y: 90, width: 100, height: 100), source: source),
            ListPlaybackCandidate(id: "best", frame: CGRect(x: 0, y: 0, width: 100, height: 80), source: source),
        ]

        let selected = coordinator.update(candidates: candidates, viewport: viewport) { candidate in
            candidate.id == "best" ? container : nil
        }

        #expect(selected?.id == "best")
        #expect(engine.loadedSource == source)
        #expect(renderView.superview === container)
    }

    @MainActor
    @Test func listPlaybackCoordinatorReattachesSameCandidateWhenPlayerMovedAway() throws {
        let engine = ListPlaybackMockEngine()
        let session = PlaybackSession(engine: engine)
        let renderView = AlloyPlayerUIKit.AlloyPlayerRenderView(session: session)
        let coordinator = ListPlaybackCoordinator(session: session, renderView: renderView)
        let container = UIView()
        let floatingContainer = UIView()
        let source = try PlaybackSource(url: #require(URL(string: "https://example.com/best.mp4")))
        let viewport = CGRect(x: 0, y: 0, width: 100, height: 100)
        let candidate = ListPlaybackCandidate(id: "best", frame: CGRect(x: 0, y: 0, width: 100, height: 80), source: source)

        _ = coordinator.update(candidates: [candidate], viewport: viewport) { _ in container }
        renderView.removeFromSuperview()
        floatingContainer.addSubview(renderView)
        _ = coordinator.update(candidates: [candidate], viewport: viewport) { _ in container }

        #expect(engine.loadCount == 1)
        #expect(renderView.superview === container)
    }

    @MainActor
    @Test func listPlaybackCoordinatorStopsWhenNoCandidateVisible() {
        let engine = ListPlaybackMockEngine()
        let session = PlaybackSession(engine: engine)
        let renderView = AlloyPlayerUIKit.AlloyPlayerRenderView(session: session)
        let coordinator = ListPlaybackCoordinator(session: session, renderView: renderView)

        let selected = coordinator.update(candidates: [], viewport: .zero) { _ in nil }

        #expect(selected == nil)
        #expect(engine.stopCount == 1)
    }

    @MainActor
    private final class ListPlaybackMockEngine: PlaybackEngine {
        private let snapshotSubject = CurrentValueSubject<PlaybackEngineSnapshot, Never>(PlaybackEngineSnapshot())
        var loadedSource: PlaybackSource?
        var loadCount = 0
        var stopCount = 0

        var snapshot: PlaybackEngineSnapshot {
            snapshotSubject.value
        }

        var snapshotPublisher: AnyPublisher<PlaybackEngineSnapshot, Never> {
            snapshotSubject.eraseToAnyPublisher()
        }

        func load(_ source: PlaybackSource) {
            loadCount += 1
            loadedSource = source
            var snapshot = self.snapshot
            snapshot.source = source
            snapshotSubject.send(snapshot)
        }

        func play() {}
        func pause() {}

        func stop() {
            stopCount += 1
        }

        func seek(to _: TimeInterval) async -> Bool {
            true
        }
    }
#endif
