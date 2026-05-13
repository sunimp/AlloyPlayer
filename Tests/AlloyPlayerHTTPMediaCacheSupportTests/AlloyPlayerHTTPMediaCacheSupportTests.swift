//
//  AlloyPlayerHTTPMediaCacheSupportTests.swift
//  AlloyPlayerHTTPMediaCacheSupport
//
//  Created by Sun on 2026/5/11.
//

import AlloyCore
@testable import AlloyPlayerHTTPMediaCacheSupport
import Foundation
import HTTPMediaCache
import Testing

@Suite("AlloyPlayerHTTPMediaCacheSupport", .serialized)
struct AlloyPlayerHTTPMediaCacheSupportTests {
    @Test("生成代理 URL 前会确保 HTTPMediaCache 已启动")
    func proxiedURLStartsCacheServer() async throws {
        await HTTPMediaCache.stop()
        let originalURL = try #require(URL(string: "https://example.com/video.mp4"))

        let proxyURL = try await AlloyPlayerHTTPMediaCacheSupport.proxyURL(for: originalURL)

        #expect(await HTTPMediaCache.isRunning)
        #expect(HTTPMediaCache.isProxyURL(proxyURL))
        #expect(HTTPMediaCache.originalURL(from: proxyURL) == originalURL)
    }

    @Test("请求头配置会下发到 HTTPMediaCache 下载链路")
    func configureRequestHeadersForCacheDownloader() async {
        let headers = [
            "Authorization": "Bearer token",
            "X-Trace-ID": "trace-1",
        ]

        await AlloyPlayerHTTPMediaCacheSupport.configureRequestHeaders(headers)

        #expect(await HTTPMediaCache.downloadAdditionalHeaders() == headers)
        #expect(Set(await HTTPMediaCache.downloadWhitelistHeaderKeys()) == Set(headers.keys))
    }

    @Test("清空请求头配置会移除 HTTPMediaCache 下载链路附加头")
    func clearRequestHeaders() async {
        await AlloyPlayerHTTPMediaCacheSupport.configureRequestHeaders(["Authorization": "Bearer token"])

        await AlloyPlayerHTTPMediaCacheSupport.configureRequestHeaders(nil)

        #expect(await HTTPMediaCache.downloadAdditionalHeaders().isEmpty)
        #expect(await HTTPMediaCache.downloadWhitelistHeaderKeys().isEmpty)
    }

    @Test("配置对象会同时控制代理 URL 和下载请求头")
    func proxyURLAppliesConfiguration() async throws {
        await HTTPMediaCache.stop()
        let originalURL = try #require(URL(string: "https://example.com/configured-video.mp4"))
        let headers = [
            "Authorization": "Bearer configured-token",
        ]
        let configuration = AlloyPlayerHTTPMediaCacheConfiguration(
            bindToLocalhost: false,
            requestHeaders: headers
        )

        let proxyURL = try await AlloyPlayerHTTPMediaCacheSupport.proxyURL(
            for: originalURL,
            configuration: configuration
        )

        #expect(await HTTPMediaCache.isRunning)
        #expect(HTTPMediaCache.isProxyURL(proxyURL))
        #expect(proxyURL.host != "127.0.0.1")
        #expect(await HTTPMediaCache.downloadAdditionalHeaders() == headers)
        #expect(await HTTPMediaCache.downloadWhitelistHeaderKeys() == Array(headers.keys).sorted())
    }

    @Test("默认配置会清空之前残留的下载请求头")
    func defaultConfigurationClearsStaleRequestHeaders() async throws {
        await AlloyPlayerHTTPMediaCacheSupport.configureRequestHeaders(["Authorization": "Bearer stale"])
        let originalURL = try #require(URL(string: "https://example.com/plain-video.mp4"))

        _ = try await AlloyPlayerHTTPMediaCacheSupport.proxyURL(
            for: originalURL,
            configuration: .default
        )

        #expect(await HTTPMediaCache.downloadAdditionalHeaders().isEmpty)
        #expect(await HTTPMediaCache.downloadWhitelistHeaderKeys().isEmpty)
    }

    @Test("代理播放源会清空交给本地代理的请求头")
    func proxySourceReturnsProxyURLAndClearsPlaybackHeaders() async throws {
        await HTTPMediaCache.stop()
        let originalURL = try #require(URL(string: "https://example.com/source-video.mp4"))
        let source = PlaybackSource(url: originalURL, headers: ["Authorization": "Bearer source"])
        let configuration = AlloyPlayerHTTPMediaCacheConfiguration(requestHeaders: ["X-Trace-ID": "trace"])

        let proxySource = try await AlloyPlayerHTTPMediaCacheSupport.proxySource(
            for: source,
            configuration: configuration
        )

        #expect(HTTPMediaCache.isProxyURL(proxySource.url))
        #expect(proxySource.headers.isEmpty)
        #expect(await HTTPMediaCache.downloadAdditionalHeaders() == [
            "Authorization": "Bearer source",
            "X-Trace-ID": "trace",
        ])
    }
}
