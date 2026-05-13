//
//  LoadState.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

/// 加载状态。
public struct LoadState: OptionSet, Equatable, Sendable {
    /// OptionSet 原始值。
    public let rawValue: Int

    /// 使用原始值创建加载状态。
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// 正在准备播放。
    public static let preparing = LoadState(rawValue: 1 << 0)

    /// 已具备播放条件。
    public static let playable = LoadState(rawValue: 1 << 1)

    /// 已具备连续播放条件。
    public static let playthroughOK = LoadState(rawValue: 1 << 2)

    /// 播放发生卡顿或等待缓冲。
    public static let stalled = LoadState(rawValue: 1 << 3)
}
