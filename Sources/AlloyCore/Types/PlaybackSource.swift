//
//  PlaybackSource.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import Foundation

/// 播放源。
public struct PlaybackSource: Equatable, Sendable {
    /// 播放资源 URL。
    public var url: URL

    /// 访问播放资源时附加的 HTTP 请求头。
    public var headers: [String: String]

    /// 创建播放源。
    public init(url: URL, headers: [String: String] = [:]) {
        self.url = url
        self.headers = headers
    }
}
