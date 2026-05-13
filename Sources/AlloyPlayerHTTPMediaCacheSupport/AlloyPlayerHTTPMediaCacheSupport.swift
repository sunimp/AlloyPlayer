//
//  AlloyPlayerHTTPMediaCacheSupport.swift
//  AlloyPlayerHTTPMediaCacheSupport
//
//  Created by Sun on 2026/5/11.
//

import AlloyCore
import Foundation
import HTTPMediaCache

/// AlloyPlayer 对 HTTPMediaCache 的可选支持入口。
public enum AlloyPlayerHTTPMediaCacheSupport {
    /// 按配置确保本地 HTTP 缓存代理服务已启动。
    public static func startIfNeeded(configuration: AlloyPlayerHTTPMediaCacheConfiguration = .default) async throws {
        guard await !HTTPMediaCache.isRunning else { return }
        try await HTTPMediaCache.start(port: configuration.port)
    }

    /// 按配置为原始资源生成 HTTPMediaCache 代理 URL。
    public static func proxyURL(
        for originalURL: URL,
        configuration: AlloyPlayerHTTPMediaCacheConfiguration = .default
    ) async throws -> URL {
        try await startIfNeeded(configuration: configuration)
        await configureRequestHeaders(configuration.requestHeaders)
        return try await HTTPMediaCache.proxyURL(
            for: originalURL,
            bindToLocalhost: configuration.bindToLocalhost
        )
    }

    /// 按配置为播放源生成 HTTPMediaCache 代理播放源。
    public static func proxySource(
        for originalSource: PlaybackSource,
        configuration: AlloyPlayerHTTPMediaCacheConfiguration = .default
    ) async throws -> PlaybackSource {
        let downloadHeaders = originalSource.headers.merging(configuration.requestHeaders) { _, new in new }
        let proxyURL = try await proxyURL(
            for: originalSource.url,
            configuration: AlloyPlayerHTTPMediaCacheConfiguration(
                port: configuration.port,
                bindToLocalhost: configuration.bindToLocalhost,
                requestHeaders: downloadHeaders
            )
        )
        return PlaybackSource(url: proxyURL, headers: [:])
    }

    /// 配置 HTTPMediaCache 下载源站资源时需要携带的请求头。
    ///
    /// AVPlayer 访问的是本地代理 URL，源站请求由 HTTPMediaCache 发出，因此需要把业务请求头显式下发到下载链路。
    public static func configureRequestHeaders(_ headers: [String: String]?) async {
        let normalizedHeaders = headers ?? [:]
        await HTTPMediaCache.setDownloadAdditionalHeaders(normalizedHeaders)
        await HTTPMediaCache.setDownloadWhitelistHeaderKeys(Array(normalizedHeaders.keys).sorted())
    }
}
