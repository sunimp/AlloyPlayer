//
//  AlloyPlayerViewConfiguration.swift
//  AlloySwiftUIControls
//
//  Created by Sun on 2026/5/9.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyCore
    import Foundation

    /// SwiftUI 播放视图配置
    public struct AlloyPlayerViewConfiguration {
        public var autoPlay = true
        public var scalingMode: ScalingMode = .aspectFit
        public var disabledGestureTypes: DisableGestureTypes = []
        public var controlAutoHideInterval: TimeInterval = 2.5
        public var pauseWhenDisappear = true
        public var stopWhenDismantle = true
        public var configurePlayer: ((Player) -> Void)?
        public var onPlaybackStateChange: ((PlaybackState) -> Void)?

        public init() {}
    }
#endif
