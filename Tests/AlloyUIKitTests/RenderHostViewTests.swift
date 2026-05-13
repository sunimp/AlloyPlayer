//
//  RenderHostViewTests.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    @testable import AlloyUIKit
    import Combine
    import CoreGraphics
    import QuartzCore
    import Testing
    import UIKit

    @MainActor
    @Suite("Render Host View Tests")
    struct RenderHostViewTests {
        @Test func playerRenderViewMovesActiveSurfaceBetweenHostsWithoutStoppingPlayback() {
            let engine = RenderViewTestEngine()
            engine.update(
                PlaybackEngineSnapshot(
                    playbackState: .playing,
                    loadState: [.playable],
                    currentTime: 18,
                    duration: 120
                )
            )
            let session = PlaybackSession(engine: engine)
            let inlineView = AlloyPlayerRenderView(session: session)
            let floatingView = AlloyPlayerRenderView(session: session)

            inlineView.activateRenderSurface()
            #expect(engine.surface.layer.superlayer === inlineView.layer)

            floatingView.activateRenderSurface()

            #expect(engine.surface.layer.superlayer === floatingView.layer)
            #expect(engine.pauseCount == 0)
            #expect(engine.stopCount == 0)
            #expect(session.state.engine.playbackState == .playing)
            #expect(session.state.engine.currentTime == 18)
        }

        @Test func attachesLayerBackedSurface() {
            let host = RenderHostView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
            let surface = MockLayerBackedSurface()

            host.attach(surface: surface)
            host.layoutIfNeeded()

            #expect(surface.layer.superlayer === host.layer)
            #expect(surface.layer.frame == host.bounds)
        }

        @Test func detachRemovesHostedLayer() {
            let host = RenderHostView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
            let surface = MockLayerBackedSurface()

            host.attach(surface: surface)
            host.detachSurface()

            #expect(surface.layer.superlayer == nil)
        }

        private final class MockLayerBackedSurface: LayerBackedRenderSurface {
            let layer = CALayer()
            var presentationSize: CGSize = .zero
        }

        private final class RenderViewTestEngine: PlaybackEngine {
            let surface = MockLayerBackedSurface()
            private let snapshotSubject = CurrentValueSubject<PlaybackEngineSnapshot, Never>(PlaybackEngineSnapshot())
            var pauseCount = 0
            var stopCount = 0

            var snapshot: PlaybackEngineSnapshot {
                snapshotSubject.value
            }

            var snapshotPublisher: AnyPublisher<PlaybackEngineSnapshot, Never> {
                snapshotSubject.eraseToAnyPublisher()
            }

            var renderSurface: PlaybackRenderSurface? {
                surface
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
    }
#endif
