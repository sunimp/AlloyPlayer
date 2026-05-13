//
//  AVPlaybackEngineTests.swift
//  AlloyAVPlayer
//
//  Created by Sun on 2026/5/13.
//

@testable import AlloyAVPlayer
import AlloyCore
import CoreMedia
import Foundation
import Testing

@MainActor
@Suite("AV Playback Engine Tests")
struct AVPlaybackEngineTests {
    @Test func loadCreatesSourceSnapshotAndRenderSurface() throws {
        let engine = AVPlaybackEngine()
        let source = try PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4")))

        engine.load(source)

        #expect(engine.snapshot.source?.url.absoluteString == "https://example.invalid/video.mp4")
        #expect(engine.snapshot.playbackState == .loading)
        #expect(engine.renderSurface != nil)
    }

    @Test func stopClearsRenderSurfaceAndMarksStopped() throws {
        let engine = AVPlaybackEngine()
        let source = try PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4")))

        engine.load(source)
        engine.stop()

        #expect(engine.snapshot.playbackState == .stopped)
        #expect(engine.renderSurface == nil)
    }

    @Test func resolvedBufferedTimeUsesFarthestLoadedRange() {
        let bufferedTime = AVPlaybackEngine.resolvedBufferedTime(
            from: [
                CMTimeRange(start: .zero, duration: CMTime(seconds: 30, preferredTimescale: 600)),
                CMTimeRange(
                    start: CMTime(seconds: 60, preferredTimescale: 600),
                    duration: CMTime(seconds: 20, preferredTimescale: 600)
                ),
            ],
            previousBufferedTime: 0,
            duration: 100
        )

        #expect(bufferedTime == 80)
    }

    @Test func resolvedBufferedTimeDoesNotRegressWithinLoadedSource() {
        let bufferedTime = AVPlaybackEngine.resolvedBufferedTime(
            from: [
                CMTimeRange(
                    start: CMTime(seconds: 50, preferredTimescale: 600),
                    duration: CMTime(seconds: 5, preferredTimescale: 600)
                ),
            ],
            previousBufferedTime: 98,
            duration: 98
        )

        #expect(bufferedTime == 98)
    }
}

@Test func moduleImports() {
    // 验证模块可正常导入
}
