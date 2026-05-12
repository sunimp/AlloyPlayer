//
//  VisibilityEvaluatorTests.swift
//  AlloyListPlaybackTests
//
//  Created by Sun on 2026/5/12.
//

@testable import AlloyListPlayback
import CoreGraphics
import Testing

@Test func visibilityEvaluatorReturnsOneForFullyVisibleRect() {
    let viewport = CGRect(x: 0, y: 0, width: 100, height: 100)
    let item = CGRect(x: 10, y: 10, width: 40, height: 40)

    #expect(VisibilityEvaluator.visiblePercent(of: item, in: viewport) == 1)
}

@Test func visibilityEvaluatorReturnsPartialVisibleAreaRatio() {
    let viewport = CGRect(x: 0, y: 0, width: 100, height: 100)
    let item = CGRect(x: 50, y: 50, width: 100, height: 100)

    #expect(VisibilityEvaluator.visiblePercent(of: item, in: viewport) == 0.25)
}

@Test func visibilityEvaluatorReturnsZeroForInvisibleOrEmptyRects() {
    let viewport = CGRect(x: 0, y: 0, width: 100, height: 100)

    #expect(VisibilityEvaluator.visiblePercent(of: CGRect(x: 200, y: 200, width: 20, height: 20), in: viewport) == 0)
    #expect(VisibilityEvaluator.visiblePercent(of: .zero, in: viewport) == 0)
}
