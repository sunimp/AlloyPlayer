//
//  AlloyHTTPMediaCacheConfiguration.swift
//  AlloyHTTPMediaCacheSupport
//
//  Created by Sun on 2026/5/12.
//

import Foundation

/// HTTPMediaCache 集成配置。
public struct AlloyHTTPMediaCacheConfiguration: Equatable, Sendable {
    /// 默认配置：随机端口、绑定 localhost、不附加源站请求头。
    public static let `default` = AlloyHTTPMediaCacheConfiguration()

    /// HTTPMediaCache 本地代理端口。传入 0 时由系统分配可用端口。
    public var port: UInt16

    /// 是否将代理地址绑定到 localhost。
    public var bindToLocalhost: Bool

    /// HTTPMediaCache 下载源站资源时附加的请求头。
    public var requestHeaders: [String: String]

    public init(
        port: UInt16 = 0,
        bindToLocalhost: Bool = true,
        requestHeaders: [String: String] = [:]
    ) {
        self.port = port
        self.bindToLocalhost = bindToLocalhost
        self.requestHeaders = requestHeaders
    }
}
