//
//  DemoPlaybackConfiguration.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/5/12.
//

import AlloyHTTPMediaCacheSupport
import AlloyPlayer
import Foundation

// MARK: - DemoPlaybackConfiguration

/// Demo 全局播放配置。
@MainActor
final class DemoPlaybackConfiguration {
    static let shared = DemoPlaybackConfiguration()

    static let didChangeNotification = Notification.Name("DemoPlaybackConfigurationDidChangeNotification")

    var isHTTPMediaCacheEnabled = false {
        didSet {
            guard isHTTPMediaCacheEnabled != oldValue else { return }
            NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
        }
    }

    private init() {}

    func playbackSource(for originalURL: URL) async throws -> PlaybackSource {
        let source = PlaybackSource(url: originalURL)
        guard isHTTPMediaCacheEnabled else {
            return source
        }

        return try await AlloyHTTPMediaCacheSupport.proxySource(
            for: source,
            configuration: .default
        )
    }
}

// MARK: - AlloyPlayerView

extension AlloyPlayerView {
    @discardableResult
    @MainActor
    func prepareDemoPlayback(originalURL: URL) async throws -> PlaybackSource {
        let source = try await DemoPlaybackConfiguration.shared.playbackSource(for: originalURL)
        load(source)
        return source
    }
}
