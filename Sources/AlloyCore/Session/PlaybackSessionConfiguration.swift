//
//  PlaybackSessionConfiguration.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import Foundation

/// 播放会话配置。
public struct PlaybackSessionConfiguration: Equatable, Sendable {
    /// 播放源准备完成后是否自动播放。
    public var autoPlay: Bool

    /// 初始播放时间，单位为秒。
    public var startTime: TimeInterval

    /// 创建播放会话配置。
    public init(autoPlay: Bool = true, startTime: TimeInterval = 0) {
        self.autoPlay = autoPlay
        self.startTime = startTime
    }
}
