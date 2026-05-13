//
//  AVPlaybackEngineTests.swift
//  AlloyAVPlayer
//
//  Created by Sun on 2026/5/13.
//

@testable import AlloyAVPlayer
import AlloyCore
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
}

@Test func moduleImports() {
    // 验证模块可正常导入
}
