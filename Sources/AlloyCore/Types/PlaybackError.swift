//
//  PlaybackError.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

/// 播放错误。
public struct PlaybackError: Error, Equatable, Sendable {
    /// 播放错误码。
    public enum Code: Equatable, Sendable {
        /// 播放源无效。
        case invalidSource

        /// 底层播放引擎失败。
        case engineFailed

        /// 跳转失败。
        case seekFailed

        /// 当前操作或媒体格式不受支持。
        case unsupported

        /// 操作已取消。
        case cancelled
    }

    /// 错误码。
    public var code: Code

    /// 面向调试和展示的错误信息。
    public var message: String

    /// 创建播放错误。
    public init(code: Code, message: String) {
        self.code = code
        self.message = message
    }
}
