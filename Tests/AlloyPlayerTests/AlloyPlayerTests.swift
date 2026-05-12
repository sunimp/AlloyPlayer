//
//  AlloyPlayerTests.swift
//  AlloyPlayerTests
//
//  Created by Sun on 2026/5/12.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyPlayer
    import SwiftUI
    import Testing

    @MainActor
    @Test func umbrellaModuleProvidesDefaultSwiftUIAVPlayerEntryPoint() {
        let url = URL(string: "https://example.invalid/video.mp4")

        _ = AlloyPlayerView(url: url)
        _ = AlloyPlayerView(url: url) { state in
            Text(state.isPlaying ? "播放中" : "未播放")
        }
    }
#endif
