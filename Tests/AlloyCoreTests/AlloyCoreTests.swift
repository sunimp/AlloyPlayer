//
//  AlloyCoreTests.swift
//  AlloyCoreTests
//
//  Created by Sun on 2026/4/14.
//

@testable import AlloyCore
import Combine
import Testing

#if canImport(UIKit)
    import UIKit
    import XCTest
#endif

@Test func moduleImports() {
    // 验证模块可正常导入
}

#if canImport(UIKit)
    @MainActor
    final class PlayerBindingTests: XCTestCase {
        func testSettingAssetURLPreparesEngineOnlyOnce() throws {
            let engine = AutoPreparingPlaybackEngine()
            let player = Player(engine: engine, containerView: UIView())
            let url = try XCTUnwrap(URL(string: "https://example.invalid/video.mp4"))

            player.assetURL = url

            XCTAssertEqual(engine.prepareCount, 1)
        }

        func testReplacingEngineMovesGesturesFromOldRenderViewToNewRenderView() {
            let oldEngine = AutoPreparingPlaybackEngine()
            let player = Player(engine: oldEngine, containerView: UIView())
            let newEngine = AutoPreparingPlaybackEngine()

            XCTAssertFalse(oldEngine.renderView.gestureRecognizers?.isEmpty ?? true)

            player.replaceEngine(newEngine)

            XCTAssertTrue(oldEngine.renderView.gestureRecognizers?.isEmpty ?? true)
            XCTAssertFalse(newEngine.renderView.gestureRecognizers?.isEmpty ?? true)
        }

        func testSystemNotificationSubscriptionsSurviveEngineReplacement() throws {
            let firstEngine = AutoPreparingPlaybackEngine()
            let player = Player(engine: firstEngine, containerView: UIView())
            let url = try XCTUnwrap(URL(string: "https://example.invalid/video.mp4"))
            player.assetURL = url

            let replacementEngine = AutoPreparingPlaybackEngine()
            player.replaceEngine(replacementEngine)

            NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)

            XCTAssertEqual(replacementEngine.pauseCount, 1)
        }
    }

    @MainActor
    private final class AutoPreparingPlaybackEngine: PlaybackEngine {
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
        var assetURL: URL? {
            didSet {
                if assetURL != oldValue, assetURL != nil {
                    prepareToPlay()
                }
            }
        }

        var presentationSize: CGSize = .zero
        var prepareCount = 0
        var pauseCount = 0

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

        func prepareToPlay() {
            prepareCount += 1
            if let assetURL {
                prepareSubject.send(assetURL)
            }
        }

        func reloadPlayer() {}
        func play() {
            isPlaying = true
        }

        func pause() {
            pauseCount += 1
            isPlaying = false
        }

        func replay() {}
        func stop() {}
        func seek(to _: TimeInterval) async -> Bool {
            true
        }
    }
#endif
