//
//  UtilitiesTests.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

@testable import AlloyCore
import Testing

@Suite("Utilities Tests")
struct UtilitiesTests {
    @Test func timeFormatterShortFormat() {
        #expect(TimeFormatter.string(from: 0) == "00:00")
        #expect(TimeFormatter.string(from: 59) == "00:59")
        #expect(TimeFormatter.string(from: 60) == "01:00")
        #expect(TimeFormatter.string(from: 125) == "02:05")
        #expect(TimeFormatter.string(from: 3599) == "59:59")
    }

    @Test func timeFormatterLongFormat() {
        #expect(TimeFormatter.string(from: 3600) == "01:00:00")
        #expect(TimeFormatter.string(from: 3661) == "01:01:01")
        #expect(TimeFormatter.string(from: 7200) == "02:00:00")
    }

    @Test func timeFormatterNegative() {
        #expect(TimeFormatter.string(from: -1) == "00:00")
    }
}
