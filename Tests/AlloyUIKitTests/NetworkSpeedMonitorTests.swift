//
//  NetworkSpeedMonitorTests.swift
//  AlloyUIKitTests
//
//  Created by Sun on 2026/5/13.
//

@testable import AlloyUIKit
import Testing

@Suite("Network Speed Monitor Tests")
struct NetworkSpeedMonitorTests {
    @Test func networkSpeedFormatterUsesDefaultUnits() {
        #expect(NetworkSpeedFormatter.string(fromBytesPerSecond: 0) == "0 B/s")
        #expect(NetworkSpeedFormatter.string(fromBytesPerSecond: 1024) == "1.0 KB/s")
        #expect(NetworkSpeedFormatter.string(fromBytesPerSecond: 1024 * 1024) == "1.0 MB/s")
    }

    @Test func networkSpeedFormatterUsesCustomUnits() {
        let configuration = NetworkSpeedFormattingConfiguration(
            bytesPerSecondUnit: "Bps",
            kilobytesPerSecondUnit: "KiBps",
            megabytesPerSecondUnit: "MiBps"
        )

        #expect(NetworkSpeedFormatter.string(fromBytesPerSecond: 1, configuration: configuration) == "1 Bps")
        #expect(NetworkSpeedFormatter.string(fromBytesPerSecond: 1024, configuration: configuration) == "1.0 KiBps")
        #expect(NetworkSpeedFormatter.string(fromBytesPerSecond: 1024 * 1024, configuration: configuration) == "1.0 MiBps")
    }
}
