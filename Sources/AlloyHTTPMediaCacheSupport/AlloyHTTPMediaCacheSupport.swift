//
//  AlloyHTTPMediaCacheSupport.swift
//  AlloyHTTPMediaCacheSupport
//
//  Created by Sun on 2026/5/11.
//

import Foundation
import HTTPMediaCache

#if canImport(UIKit)
    import AlloyCore
#endif

/// AlloyPlayer 对 HTTPMediaCache 的可选支持入口。
public enum AlloyHTTPMediaCacheSupport {
    /// 确保本地 HTTP 缓存代理服务已启动。
    public static func startIfNeeded(port: UInt16 = 0) async throws {
        try await startIfNeeded(configuration: .init(port: port))
    }

    /// 按配置确保本地 HTTP 缓存代理服务已启动。
    public static func startIfNeeded(configuration: AlloyHTTPMediaCacheConfiguration = .default) async throws {
        guard await !HTTPMediaCache.isRunning else { return }
        try await HTTPMediaCache.start(port: configuration.port)
    }

    /// 为原始资源生成 HTTPMediaCache 代理 URL。
    public static func proxyURL(
        for originalURL: URL,
        bindToLocalhost: Bool = true,
        port: UInt16 = 0
    ) async throws -> URL {
        try await proxyURL(
            for: originalURL,
            configuration: .init(port: port, bindToLocalhost: bindToLocalhost)
        )
    }

    /// 按配置为原始资源生成 HTTPMediaCache 代理 URL。
    public static func proxyURL(
        for originalURL: URL,
        configuration: AlloyHTTPMediaCacheConfiguration = .default
    ) async throws -> URL {
        try await startIfNeeded(configuration: configuration)
        await configureRequestHeaders(configuration.requestHeaders)
        return try await HTTPMediaCache.proxyURL(
            for: originalURL,
            bindToLocalhost: configuration.bindToLocalhost
        )
    }

    /// 配置 HTTPMediaCache 下载源站资源时需要携带的请求头。
    ///
    /// AVPlayer 访问的是本地代理 URL，源站请求由 HTTPMediaCache 发出，因此需要把业务请求头显式下发到下载链路。
    public static func configureRequestHeaders(_ headers: [String: String]?) async {
        let normalizedHeaders = headers ?? [:]
        await HTTPMediaCache.setDownloadAdditionalHeaders(normalizedHeaders)
        await HTTPMediaCache.setDownloadWhitelistHeaderKeys(Array(normalizedHeaders.keys).sorted())
    }

    #if canImport(UIKit)
        /// 将原始资源转换为 HTTPMediaCache 代理 URL 后交给播放器准备播放。
        @discardableResult
        @MainActor
        public static func prepare(
            player: Player,
            originalURL: URL,
            requestHeaders: [String: String]? = nil,
            bindToLocalhost: Bool = true,
            port: UInt16 = 0
        ) async throws -> URL {
            try await prepare(
                player: player,
                originalURL: originalURL,
                configuration: .init(
                    port: port,
                    bindToLocalhost: bindToLocalhost,
                    requestHeaders: requestHeaders ?? [:]
                )
            )
        }

        /// 按配置将原始资源转换为 HTTPMediaCache 代理 URL 后交给播放器准备播放。
        @discardableResult
        @MainActor
        public static func prepare(
            player: Player,
            originalURL: URL,
            configuration: AlloyHTTPMediaCacheConfiguration = .default
        ) async throws -> URL {
            let proxyURL = try await proxyURL(
                for: originalURL,
                configuration: configuration
            )
            player.assetURL = proxyURL
            return proxyURL
        }
    #endif
}
