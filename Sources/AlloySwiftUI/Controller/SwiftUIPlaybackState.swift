//
//  SwiftUIPlaybackState.swift
//  AlloySwiftUI
//
//  Created by Sun on 2026/5/13.
//

#if canImport(SwiftUI)
    import AlloyCore

    /// SwiftUI 展示层播放状态。
    public struct SwiftUIPlaybackState: Equatable, Sendable {
        public var snapshot: PlaybackStateSnapshot

        public init(snapshot: PlaybackStateSnapshot) {
            self.snapshot = snapshot
        }
    }
#endif
