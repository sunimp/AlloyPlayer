//
//  ListPlaybackEventSink.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/12.
//

#if canImport(UIKit)
    import UIKit

    /// 列表播放事件接收者。
    @MainActor
    public protocol ListPlaybackEventSink: AnyObject {
        func playerWillAppearInScrollView(_ player: Player)
        func playerDidAppearInScrollView(_ player: Player)
        func playerWillDisappearInScrollView(_ player: Player)
        func playerDidDisappearInScrollView(_ player: Player)
        func player(_ player: Player, appearingPercent: CGFloat)
        func player(_ player: Player, disappearingPercent: CGFloat)
        func player(_ player: Player, floatViewShow isShow: Bool)
    }

    public extension ListPlaybackEventSink {
        func playerWillAppearInScrollView(_: Player) {}
        func playerDidAppearInScrollView(_: Player) {}
        func playerWillDisappearInScrollView(_: Player) {}
        func playerDidDisappearInScrollView(_: Player) {}
        func player(_: Player, appearingPercent _: CGFloat) {}
        func player(_: Player, disappearingPercent _: CGFloat) {}
        func player(_: Player, floatViewShow _: Bool) {}
    }
#endif
