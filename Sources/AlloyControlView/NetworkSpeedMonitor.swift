//
//  NetworkSpeedMonitor.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

import Combine
import Foundation

/// 网速监控器
///
/// 通过读取系统网络接口统计数据计算上传/下载速度。
@MainActor
public final class NetworkSpeedMonitor {
    public private(set) var downloadSpeed: String = "0 KB/s"
    public private(set) var uploadSpeed: String = "0 KB/s"

    private let _speed = PassthroughSubject<(download: String, upload: String), Never>()
    public var speedPublisher: AnyPublisher<(download: String, upload: String), Never> {
        _speed.eraseToAnyPublisher()
    }

    private var timer: Timer?
    private var lastBytesReceived: UInt64 = 0
    private var lastBytesSent: UInt64 = 0

    public init() {}

    public func startMonitoring() {
        let (rx, tx) = getNetworkBytes()
        lastBytesReceived = rx
        lastBytesSent = tx
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func update() {
        let (rx, tx) = getNetworkBytes()
        let rxDiff = rx > lastBytesReceived ? rx - lastBytesReceived : 0
        let txDiff = tx > lastBytesSent ? tx - lastBytesSent : 0
        lastBytesReceived = rx
        lastBytesSent = tx
        downloadSpeed = formatBytes(rxDiff)
        uploadSpeed = formatBytes(txDiff)
        _speed.send((download: downloadSpeed, upload: uploadSpeed))
    }

    #if canImport(UIKit)
        private nonisolated func getNetworkBytes() -> (received: UInt64, sent: UInt64) {
            var ifaddr: UnsafeMutablePointer<ifaddrs>?
            guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return (0, 0) }
            defer { freeifaddrs(ifaddr) }

            var rx: UInt64 = 0
            var tx: UInt64 = 0
            for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
                guard ptr.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK) else { continue }
                let data = unsafeBitCast(ptr.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
                rx += UInt64(data.pointee.ifi_ibytes)
                tx += UInt64(data.pointee.ifi_obytes)
            }
            return (rx, tx)
        }
    #else
        private nonisolated func getNetworkBytes() -> (received: UInt64, sent: UInt64) {
            (0, 0)
        }
    #endif

    private func formatBytes(_ bytes: UInt64) -> String {
        if bytes < 1024 { return "\(bytes) B/s" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB/s", Double(bytes) / 1024) }
        return String(format: "%.1f MB/s", Double(bytes) / 1024 / 1024)
    }
}
