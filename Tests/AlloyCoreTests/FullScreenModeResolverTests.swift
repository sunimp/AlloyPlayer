//
//  FullScreenModeResolverTests.swift
//  AlloyCoreTests
//
//  Created by Sun on 2026/5/12.
//

@testable import AlloyCore
import CoreGraphics
import Testing

@Test func fullScreenModeResolverHonorsExplicitModes() {
    #expect(FullScreenModeResolver.resolve(mode: .landscape, presentationSize: CGSize(width: 720, height: 1280)) == .landscape)
    #expect(FullScreenModeResolver.resolve(mode: .portrait, presentationSize: CGSize(width: 1920, height: 1080)) == .portrait)
}

@Test func fullScreenModeResolverUsesAspectRatioForAutomaticMode() {
    #expect(FullScreenModeResolver.resolve(mode: .automatic, presentationSize: CGSize(width: 1920, height: 1080)) == .landscape)
    #expect(FullScreenModeResolver.resolve(mode: .automatic, presentationSize: CGSize(width: 720, height: 1280)) == .portrait)
}

@Test func fullScreenModeResolverDefaultsUnknownSizeToPortrait() {
    #expect(FullScreenModeResolver.resolve(mode: .automatic, presentationSize: .zero) == .portrait)
    #expect(FullScreenModeResolver.resolve(mode: .automatic, presentationSize: CGSize(width: 0, height: 1080)) == .portrait)
}
