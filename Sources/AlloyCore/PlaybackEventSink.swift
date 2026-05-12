//
//  PlaybackEventSink.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/12.
//

#if canImport(UIKit)
    import CoreGraphics
    import Foundation

    /// 播放事件接收者。
    @MainActor
    public protocol PlaybackEventSink: AnyObject {
        func player(_ player: Player, prepareToPlay assetURL: URL)
        func player(_ player: Player, didChangePlaybackState state: PlaybackState)
        func player(_ player: Player, didChangeLoadState state: LoadState)
        func player(_ player: Player, didUpdateTime currentTime: TimeInterval, totalTime: TimeInterval)
        func player(_ player: Player, didUpdateBufferTime bufferTime: TimeInterval)
        func player(_ player: Player, draggingTime: TimeInterval, totalTime: TimeInterval)
        func playerDidPlayToEnd(_ player: Player)
        func player(_ player: Player, didFailWithError error: any Error)
        func player(_ player: Player, didChangePresentationSize size: CGSize)
    }

    public extension PlaybackEventSink {
        func player(_: Player, prepareToPlay _: URL) {}
        func player(_: Player, didChangePlaybackState _: PlaybackState) {}
        func player(_: Player, didChangeLoadState _: LoadState) {}
        func player(_: Player, didUpdateTime _: TimeInterval, totalTime _: TimeInterval) {}
        func player(_: Player, didUpdateBufferTime _: TimeInterval) {}
        func player(_: Player, draggingTime _: TimeInterval, totalTime _: TimeInterval) {}
        func playerDidPlayToEnd(_: Player) {}
        func player(_: Player, didFailWithError _: any Error) {}
        func player(_: Player, didChangePresentationSize _: CGSize) {}
    }
#endif
