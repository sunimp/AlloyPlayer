//
//  PlaybackTypesTests.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

@testable import AlloyCore
import Foundation
import Testing

@Suite("Playback Types Tests")
struct PlaybackTypesTests {
    @Test func loadStateContainsPlayable() {
        #expect(LoadState.playable.contains(.playable))
    }

    @Test func scalingModesAreDistinct() {
        #expect(ScalingMode.aspectFit != .aspectFill)
    }

    @Test func playbackSourceDefaultsHeadersToEmpty() throws {
        let url = try #require(URL(string: "https://example.invalid/video.mp4"))
        #expect(PlaybackSource(url: url).headers.isEmpty)
    }

    @Test func playbackErrorExposesCode() {
        #expect(PlaybackError(code: .invalidSource, message: "bad").code == .invalidSource)
    }
}
