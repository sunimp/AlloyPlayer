//
//  PlaybackEngineEvent.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import CoreGraphics
import Foundation

/// 播放引擎事件。
public enum PlaybackEngineEvent: Equatable, Sendable {
    /// 播放源已加载。
    case didLoad(PlaybackSource)

    /// 播放源已准备好播放。
    case readyToPlay(PlaybackSource)

    /// 当前播放源已播放至结尾。
    case didPlayToEnd

    /// 播放引擎发生错误。
    case failed(PlaybackError)

    /// 跳转操作已完成。
    case seekCompleted(time: TimeInterval, finished: Bool)

    /// 视频展示尺寸发生变化。
    case presentationSizeChanged(CGSize)
}
