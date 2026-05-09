//
//  AlloySwiftUIControlsTests.swift
//  AlloySwiftUIControlsTests
//
//  Created by Sun on 2026/5/9.
//

#if canImport(UIKit) && canImport(SwiftUI)
    @testable import AlloySwiftUIControls
    import SwiftUI
    import Testing

    @Test func moduleImports() {
        // 验证 SwiftUI 桥接模块可正常导入
    }

    @MainActor
    @Test func playerViewSupportsDefaultAndCustomControls() {
        let url = URL(string: "https://example.invalid/video.mp4")
        let controller = AlloyPlayerController()

        _ = AlloyPlayerView(url: url)
            .autoPlay(true)
            .scalingMode(.aspectFit)
            .controlAutoHideInterval(2.5)
            .pauseWhenDisappear(true)
            .configurePlayer { _ in }
            .onPlaybackStateChange { _ in }

        _ = AlloyPlayerView(url: url, controller: controller) { state in
            VStack {
                SwiftUIPlaybackProgressBar(state: state)
                Text(state.isPlaying ? "播放中" : "未播放")
            }
        }
        .disabledGestures([.pinch])
    }
#endif
