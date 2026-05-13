//
//  PlaybackSource.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

import Foundation

/// 播放源。
public struct PlaybackSource: Equatable, Sendable {
    public var url: URL
    public var headers: [String: String]

    public init(url: URL, headers: [String: String] = [:]) {
        self.url = url
        self.headers = headers
    }
}
