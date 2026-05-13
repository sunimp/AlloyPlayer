//
//  SwiftUIPlaybackState.swift
//  AlloySwiftUI
//
//  Created by Sun on 2026/5/13.
//

#if canImport(SwiftUI)
    import AlloyCore

    /// SwiftUI 展示层播放状态。
    struct SwiftUIPlaybackState: Equatable {
        var snapshot: PlaybackStateSnapshot

        init(snapshot: PlaybackStateSnapshot) {
            self.snapshot = snapshot
        }
    }
#endif
