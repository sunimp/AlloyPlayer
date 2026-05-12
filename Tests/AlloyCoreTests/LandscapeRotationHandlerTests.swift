//
//  LandscapeRotationHandlerTests.swift
//  AlloyCoreTests
//
//  Created by Sun on 2026/5/12.
//

@testable import AlloyCore
import Testing

#if canImport(UIKit)
    import UIKit

    @MainActor
    @Test func landscapeRotationHandlerCompletesWithoutCrashWhenSceneIsUnavailable() {
        let handler = LandscapeRotationHandler()
        handler.windowSceneProvider = { nil }
        handler.updateViews(contentView: UIView(), containerView: UIView())
        var didChange = false
        var didComplete = false
        handler.orientationDidChange = { _ in didChange = true }

        handler.rotate(to: .landscapeRight, animated: false) {
            didComplete = true
        }

        #expect(didComplete)
        #expect(didChange == false)
        #expect(handler.currentOrientation == .portrait)
    }
#endif
