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
    }
#endif
