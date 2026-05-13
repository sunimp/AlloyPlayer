//
//  RenderHostViewTests.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    @testable import AlloyUIKit
    import CoreGraphics
    import QuartzCore
    import Testing
    import UIKit

    @MainActor
    @Suite("Render Host View Tests")
    struct RenderHostViewTests {
        @Test func attachesLayerBackedSurface() {
            let host = RenderHostView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
            let surface = MockLayerBackedSurface()

            host.attach(surface: surface)
            host.layoutIfNeeded()

            #expect(surface.layer.superlayer === host.layer)
            #expect(surface.layer.frame == host.bounds)
        }

        @Test func detachRemovesHostedLayer() {
            let host = RenderHostView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
            let surface = MockLayerBackedSurface()

            host.attach(surface: surface)
            host.detachSurface()

            #expect(surface.layer.superlayer == nil)
        }

        private final class MockLayerBackedSurface: LayerBackedRenderSurface {
            let layer = CALayer()
            var presentationSize: CGSize = .zero
        }
    }
#endif
