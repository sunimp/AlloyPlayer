//
//  AlloySwiftUITests.swift
//  AlloySwiftUITests
//
//  Created by Sun on 2026/5/9.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyCore
    @testable import AlloySwiftUI
    import Combine
    import SwiftUI
    import Testing
    import UIKit

    @Test func moduleImports() {
        // 验证 SwiftUI 桥接模块可正常导入
    }

    @MainActor
    @Test func playerViewSupportsDefaultAndCustomControls() {
        let url = URL(string: "https://example.invalid/video.mp4")
        let controller = AlloyPlayerController()

        _ = AlloyPlayerView(url: url, engineFactory: { RetainTestPlaybackEngine() })
            .autoPlay(true)
            .scalingMode(.aspectFit)
            .controlAutoHideInterval(2.5)
            .pauseWhenDisappear(true)
            .configurePlayer { _ in }
            .onPlaybackStateChange { _ in }

        _ = AlloyPlayerView(url: url, controller: controller, engineFactory: { RetainTestPlaybackEngine() }) { state in
            VStack {
                SwiftUIPlaybackProgressBar(state: state)
                Text(state.isPlaying ? "播放中" : "未播放")
            }
        }
        .disabledGestures([.pinch])
    }

    @MainActor
    @Test func playerDrivenStateUpdatesAreDeferred() async throws {
        let state = SwiftUIControlOverlayState()
        let url = try #require(URL(string: "https://example.invalid/video.mp4"))
        var activeURL: URL?
        let cancellable = state.$activeURL.dropFirst().sink { value in
            activeURL = value
        }

        state.updatePrepareToPlay(url: url)

        #expect(activeURL == nil)

        await Task.yield()

        #expect(activeURL == url)
        _ = cancellable
    }

    @MainActor
    @Test func controlOverlayStateDoesNotRetainPlayer() async {
        let state = SwiftUIControlOverlayState()
        weak var weakPlayer: Player?

        do {
            let player = Player(engine: RetainTestPlaybackEngine(), containerView: UIView())
            weakPlayer = player
            state.attach(player: player)
        }

        await Task.yield()

        #expect(weakPlayer == nil)
        #expect(state.player == nil)
    }

    @MainActor
    private final class RetainTestPlaybackEngine: PlaybackEngine {
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
