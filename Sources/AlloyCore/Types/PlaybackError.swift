//
//  PlaybackError.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

/// 播放错误。
public struct PlaybackError: Error, Equatable, Sendable {
    public enum Code: Equatable, Sendable {
        case invalidSource
        case engineFailed
        case seekFailed
        case unsupported
        case cancelled
    }

    public var code: Code
    public var message: String

    public init(code: Code, message: String) {
        self.code = code
        self.message = message
    }
}
