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
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        window.addSubview(parentView)
        let session = PlaybackSession(engine: FloatingPlaybackMockEngine())
        let renderView = AlloyUIKit.AlloyPlayerRenderView(session: session)
        let coordinator = FloatingPlaybackCoordinator(session: session, renderView: renderView)

        coordinator.show(in: parentView, frame: CGRect(x: 10, y: 20, width: 160, height: 90))

        #expect(coordinator.isVisible)
        #expect(renderView.superview is FloatingPlaybackView)
        #expect(renderView.superview?.superview === window)

        (renderView.superview as? FloatingPlaybackView)?.closeAction?()

        #expect(!coordinator.isVisible)
        #expect(renderView.superview == nil)
    }

    @MainActor
    @Test func floatingPlaybackCoordinatorKeepsCurrentPlaybackStateVisibleInOverlay() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let inlineContainer = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
        window.addSubview(parentView)
        parentView.addSubview(inlineContainer)

        let engine = FloatingPlaybackMockEngine()
        engine.update(
            PlaybackEngineSnapshot(
                playbackState: .playing,
                loadState: [.playable],
                currentTime: 12,
                duration: 100,
                bufferedTime: 40
            )
        )
        let session = PlaybackSession(engine: engine)
        let renderView = AlloyUIKit.AlloyPlayerRenderView(session: session)
        inlineContainer.addSubview(renderView)
        let coordinator = FloatingPlaybackCoordinator(session: session, renderView: renderView)

        coordinator.show(in: parentView, frame: CGRect(x: 10, y: 20, width: 200, height: 112))

        let floatingView = try? #require(renderView.superview as? FloatingPlaybackView)
        #expect(floatingView?.allLabels().contains { $0.text == "00:12 / 01:40" } == true)
        #expect(engine.pauseCount == 0)
        #expect(engine.stopCount == 0)
    }

    @MainActor
    @Test func floatingPlaybackOverlayUsesCompactControlsForSmallWindow() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        window.addSubview(parentView)
        let session = PlaybackSession(engine: FloatingPlaybackMockEngine())
        let renderView = AlloyUIKit.AlloyPlayerRenderView(session: session)
        let coordinator = FloatingPlaybackCoordinator(session: session, renderView: renderView)

        coordinator.show(in: parentView, frame: CGRect(x: 10, y: 20, width: 200, height: 112))
        window.layoutIfNeeded()

        let floatingView = try? #require(renderView.superview as? FloatingPlaybackView)
        let buttons = floatingView?.allButtons() ?? []
        let closeButton = try? #require(buttons.first { $0.frame.width <= 24 && $0.frame.height <= 24 })
        let playButton = try? #require(buttons.first { $0.frame.width > 24 && $0.frame.height > 24 })
        let timeLabel = try? #require(floatingView?.allLabels().first { $0.text == "00:00 / 00:00" })
        let slider = try? #require(floatingView?.allProgressSliders().first)

        #expect(closeButton?.bounds.size == CGSize(width: 22, height: 22))
        #expect(playButton?.bounds.size == CGSize(width: 38, height: 38))
        #expect(timeLabel?.font.pointSize == 9)
        #expect(slider?.bounds.height == 18)
        #expect(slider?.thumbSize == CGSize(width: 8, height: 8))
    }

    @MainActor
    @Test func floatingPlaybackSeekDoesNotResumePlayback() throws {
        let overlay = FloatingPlaybackOverlay(frame: CGRect(x: 0, y: 0, width: 200, height: 112))
        var actions: [PlaybackControlAction] = []
        overlay.actionHandler = { actions.append($0) }
        overlay.render(state: PlaybackStateSnapshot(
            engine: PlaybackEngineSnapshot(playbackState: .playing, currentTime: 10, duration: 100)
        ))

        let slider = try #require(overlay.allProgressSliders().first)
        slider.beginTrackInteraction(at: CGPoint(x: 100, y: 9))
        slider.endTrackInteraction(at: CGPoint(x: 100, y: 9))

        #expect(actions == [.seek(50)])
    }

    @MainActor
    private final class FloatingPlaybackMockEngine: PlaybackEngine {
        private let snapshotSubject = CurrentValueSubject<PlaybackEngineSnapshot, Never>(PlaybackEngineSnapshot())
        var pauseCount = 0
        var stopCount = 0

        var snapshot: PlaybackEngineSnapshot {
            snapshotSubject.value
        }

        var snapshotPublisher: AnyPublisher<PlaybackEngineSnapshot, Never> {
            snapshotSubject.eraseToAnyPublisher()
        }

        func play() {}

        func pause() {
            pauseCount += 1
        }

        func stop() {
            stopCount += 1
        }

        func seek(to _: TimeInterval) async -> Bool {
            true
        }

        func update(_ snapshot: PlaybackEngineSnapshot) {
            snapshotSubject.send(snapshot)
        }
    }

    private extension UIView {
        func allLabels() -> [UILabel] {
            subviews.flatMap { view -> [UILabel] in
                let nestedLabels = view.allLabels()
                guard let label = view as? UILabel else { return nestedLabels }
                return [label] + nestedLabels
            }
        }

        func allButtons() -> [UIButton] {
            subviews.flatMap { view -> [UIButton] in
                let nestedButtons = view.allButtons()
                guard let button = view as? UIButton else { return nestedButtons }
                return [button] + nestedButtons
            }
        }

        func allProgressSliders() -> [ProgressSlider] {
            subviews.flatMap { view -> [ProgressSlider] in
                let nestedSliders = view.allProgressSliders()
                guard let slider = view as? ProgressSlider else { return nestedSliders }
                return [slider] + nestedSliders
            }
        }
    }
#endif
