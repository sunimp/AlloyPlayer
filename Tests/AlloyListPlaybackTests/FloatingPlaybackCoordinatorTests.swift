//
//  FloatingPlaybackCoordinatorTests.swift
//  AlloyListPlaybackTests
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    @testable import AlloyListPlayback
    import AlloyUIKit
    import Combine
    import Foundation
    import Testing
    import UIKit

    @MainActor
    @Test func floatingPlaybackCoordinatorShowsAndHidesPlayerView() {
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let playerView = AlloyUIKit.AlloyPlayerView(session: PlaybackSession(engine: FloatingPlaybackMockEngine()))
        let coordinator = FloatingPlaybackCoordinator(playerView: playerView)

        coordinator.show(in: parentView, frame: CGRect(x: 10, y: 20, width: 160, height: 90))

        #expect(coordinator.isVisible)
        #expect(playerView.superview is FloatingPlaybackView)
        #expect(playerView.superview?.superview === parentView)

        coordinator.hide()

        #expect(!coordinator.isVisible)
        #expect(playerView.superview == nil)
    }

    @MainActor
    private final class FloatingPlaybackMockEngine: PlaybackEngine {
        private let snapshotSubject = CurrentValueSubject<PlaybackEngineSnapshot, Never>(PlaybackEngineSnapshot())

        var snapshot: PlaybackEngineSnapshot {
            snapshotSubject.value
        }

        var snapshotPublisher: AnyPublisher<PlaybackEngineSnapshot, Never> {
            snapshotSubject.eraseToAnyPublisher()
        }

        func play() {}
        func pause() {}
        func stop() {}
        func seek(to _: TimeInterval) async -> Bool {
            true
        }
    }
#endif
