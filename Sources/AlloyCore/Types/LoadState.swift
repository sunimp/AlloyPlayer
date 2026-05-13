//
//  LoadState.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

/// 加载状态。
public struct LoadState: OptionSet, Equatable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let preparing = LoadState(rawValue: 1 << 0)
    public static let playable = LoadState(rawValue: 1 << 1)
    public static let playthroughOK = LoadState(rawValue: 1 << 2)
    public static let stalled = LoadState(rawValue: 1 << 3)
}
