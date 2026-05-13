//
//  FullscreenCoordinatorTests.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    @testable import AlloyUIKit
    import Testing

    @MainActor
    @Suite("Fullscreen Coordinator Tests")
    struct FullscreenCoordinatorTests {
        @Test func toggleUpdatesState() async {
            let coordinator = FullscreenCoordinator()

            await coordinator.toggle(animated: false)
            #expect(coordinator.state == .fullscreen)

            await coordinator.toggle(animated: false)
            #expect(coordinator.state == .inline)
        }

        @Test func explicitStateUpdateWorks() async {
            let coordinator = LandscapeFullscreenCoordinator()

            await coordinator.setFullscreen(true, animated: false)

            #expect(coordinator.state == .fullscreen)
        }
    }
#endif
