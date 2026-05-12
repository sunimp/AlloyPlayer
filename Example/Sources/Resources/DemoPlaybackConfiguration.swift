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

    func playbackURL(for originalURL: URL) async throws -> URL {
        guard isHTTPMediaCacheEnabled else {
            return originalURL
        }

        return try await AlloyHTTPMediaCacheSupport.proxyURL(
            for: originalURL,
            configuration: .default
        )
    }
}

// MARK: - Player

extension Player {
    @discardableResult
    @MainActor
    func prepareDemoPlayback(originalURL: URL) async throws -> URL {
        guard DemoPlaybackConfiguration.shared.isHTTPMediaCacheEnabled else {
            assetURL = originalURL
            return originalURL
        }

        return try await AlloyHTTPMediaCacheSupport.prepare(
            player: self,
            originalURL: originalURL,
            configuration: .default
        )
    }
}

// MARK: - AVPlayerManager

extension AVPlayerManager {
    @discardableResult
    @MainActor
    func prepareDemoPlayback(originalURL: URL) async throws -> URL {
        guard DemoPlaybackConfiguration.shared.isHTTPMediaCacheEnabled else {
            assetURL = originalURL
            return originalURL
        }

        let proxyURL = try await DemoPlaybackConfiguration.shared.playbackURL(for: originalURL)
        assetURL = proxyURL
        return proxyURL
    }
}
