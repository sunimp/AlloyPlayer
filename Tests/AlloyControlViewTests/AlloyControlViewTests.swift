@testable import AlloyControlView
import Combine
import Testing

#if canImport(UIKit)
    import AlloyCore
    import UIKit
    import XCTest
#endif

@Test func moduleImports() {
    // 验证模块可正常导入
}

#if canImport(UIKit)
    @MainActor
    final class ProgressSliderTests: XCTestCase {
        func testHiddenThumbSliderSupportsTrackDragging() {
            let slider = ProgressSlider(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
            slider.isThumbHidden = true
            slider.layoutIfNeeded()

            var beganValues: [Float] = []
            var changedValues: [Float] = []
            var endedValues: [Float] = []
            var cancellables = Set<AnyCancellable>()

            slider.touchBeganPublisher.sink { beganValues.append($0) }.store(in: &cancellables)
            slider.valueChangedPublisher.sink { changedValues.append($0) }.store(in: &cancellables)
            slider.touchEndedPublisher.sink { endedValues.append($0) }.store(in: &cancellables)

            slider.beginTrackInteraction(at: CGPoint(x: 50, y: 15))
            slider.updateTrackInteraction(at: CGPoint(x: 75, y: 15))
            slider.endTrackInteraction(at: CGPoint(x: 75, y: 15))

            XCTAssertEqual(beganValues.count, 1)
            XCTAssertEqual(changedValues.count, 1)
            XCTAssertEqual(endedValues.count, 1)
            XCTAssertFalse(slider.isDragging)
            XCTAssertEqual(changedValues[0], 0.8086, accuracy: 0.001)
            XCTAssertEqual(endedValues[0], 0.8086, accuracy: 0.001)
        }

        func testLoadingAnimationStaysInsideTrackBounds() {
            let slider = ProgressSlider(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
            slider.layoutIfNeeded()

            slider.startLoading()

            let loadingBar = slider.subviews[3]
            let animation = loadingBar.layer.animation(forKey: "loading") as? CAAnimationGroup
            let positionAnimation = animation?.animations?.compactMap { $0 as? CABasicAnimation }.first { $0.keyPath == "position.x" }
            let fromValue = CGFloat(truncating: positionAnimation?.fromValue as? NSNumber ?? 0)
            let toValue = CGFloat(truncating: positionAnimation?.toValue as? NSNumber ?? 0)

            XCTAssertEqual(fromValue, loadingBar.frame.midX, accuracy: 0.001)
            XCTAssertEqual(toValue, 80.5, accuracy: 0.001)
            XCTAssertGreaterThanOrEqual(fromValue, loadingBar.frame.width / 2)
            XCTAssertLessThanOrEqual(toValue, slider.bounds.width - loadingBar.frame.width / 2)
        }
    }

    @MainActor
    final class DefaultControlOverlayTests: XCTestCase {
        func testShowDisplaysToolbarThenAutoHidesToBottomProgress() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
            overlay.autoHideInterval = 0.01

            overlay.show(title: "测试视频", coverImage: nil, fullScreenMode: .automatic)

            XCTAssertTrue(overlay.isControlViewVisible)
            XCTAssertTrue(overlay.bottomProgress.isHidden)
            XCTAssertTrue(overlay.portraitPanel.playPauseButton.isHidden)
            XCTAssertEqual(overlay.portraitPanel.bottomToolBar.alpha, 1)

            let expectation = expectation(description: "控制条自动隐藏")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                XCTAssertFalse(overlay.isControlViewVisible)
                XCTAssertFalse(overlay.bottomProgress.isHidden)
                XCTAssertEqual(overlay.portraitPanel.bottomToolBar.alpha, 0)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1)
        }

        func testPlayButtonOnlyShowsWhenUserPaused() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
            let engine = RetryPlaybackEngine()
            let player = Player(engine: engine, containerView: UIView())
            player.controlOverlay = overlay

            overlay.show(title: "测试视频", coverImage: nil, fullScreenMode: .automatic)
            XCTAssertTrue(overlay.portraitPanel.playPauseButton.isHidden)

            engine.playbackState = .playing
            overlay.player(player, didChangePlaybackState: .playing)
            overlay.player(player, didChangeLoadState: .stalled)
            XCTAssertTrue(overlay.portraitPanel.playPauseButton.isHidden)

            engine.playbackState = .paused
            overlay.player(player, didChangeLoadState: .playable)
            overlay.player(player, didChangePlaybackState: .paused)
            XCTAssertFalse(overlay.portraitPanel.playPauseButton.isHidden)
        }

        func testFailureStateShowsOnlyRetryButton() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 320, height: 180))

            overlay.show(title: "测试视频", coverImage: nil, fullScreenMode: .automatic)
            overlay.player(Player(engine: RetryPlaybackEngine(), containerView: UIView()), didChangePlaybackState: .failed)

            XCTAssertFalse(overlay.failButton.isHidden)
            XCTAssertTrue(overlay.bottomProgress.isHidden)
            XCTAssertTrue(overlay.portraitPanel.isHidden)
            XCTAssertTrue(overlay.landscapePanel.isHidden)
        }

        func testRetryButtonReloadsPlayer() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
            let engine = RetryPlaybackEngine()
            let player = Player(engine: engine, containerView: UIView())
            player.controlOverlay = overlay

            overlay.player(player, didChangePlaybackState: .failed)

            XCTAssertTrue(overlay.failButton.actions(forTarget: overlay, forControlEvent: .touchUpInside)?.contains("failButtonTapped") == true)
            overlay.retryPlayback()

            XCTAssertEqual(engine.reloadCount, 1)
        }
    }

    @MainActor
    private final class RetryPlaybackEngine: PlaybackEngine {
        let renderView = RenderView()
        var playbackState: PlaybackState = .unknown
        var loadState: LoadState = .unknown
        var isPlaying = false
        var isPreparedToPlay = false
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
        var reloadCount = 0

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
        func reloadPlayer() {
            reloadCount += 1
        }

        func play() {
            isPlaying = true
        }

        func pause() {
            isPlaying = false
        }

        func replay() {}
        func stop() {}
        func seek(to _: TimeInterval) async -> Bool {
            true
        }
    }
#endif
