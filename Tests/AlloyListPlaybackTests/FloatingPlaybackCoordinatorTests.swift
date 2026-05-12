//
//  FloatingPlaybackCoordinatorTests.swift
//  AlloyListPlaybackTests
//
//  Created by Sun on 2026/5/12.
//

@testable import AlloyListPlayback
import Combine
import Foundation
import Testing

#if canImport(UIKit)
    import AlloyCore
    import UIKit

    @MainActor
    @Test func floatingPlaybackCoordinatorShowsAndHidesRenderSurface() {
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let engine = FloatingPlaybackMockEngine()
        let player = Player(engine: engine, containerView: UIView())
        let coordinator = FloatingPlaybackCoordinator(player: player, parentView: parentView)

        coordinator.show()

        #expect(coordinator.isVisible)
        #expect(coordinator.floatingView?.superview === parentView)
        #expect(engine.renderSurface.view.superview === coordinator.floatingView)

        coordinator.hide()

        #expect(!coordinator.isVisible)
        #expect(coordinator.floatingView == nil)
        #expect(engine.renderSurface.view.superview == nil)
    }

    @MainActor
    private final class FloatingPlaybackMockEngine: PlaybackEngine {
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
