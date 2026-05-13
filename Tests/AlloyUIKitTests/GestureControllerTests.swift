//
//  GestureControllerTests.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    @testable import AlloyUIKit
    import Testing
    import UIKit

    @MainActor
    @Suite("Gesture Controller Tests")
    struct GestureControllerTests {
        @Test func attachAddsRecognizersAndDetachRemovesThem() {
            let view = UIView()
            let controller = GestureController()

            controller.attach(to: view)
            #expect((view.gestureRecognizers?.count ?? 0) == 5)

            controller.detach()
            #expect(view.gestureRecognizers?.isEmpty ?? true)
        }

        @Test func configurationStoresDisabledGestures() {
            let configuration = GestureConfiguration(disabledTypes: [.doubleTap], disabledPanDirections: [.vertical])

            #expect(configuration.disabledTypes.contains(.doubleTap))
            #expect(configuration.disabledPanDirections.contains(.vertical))
        }
    }
#endif
