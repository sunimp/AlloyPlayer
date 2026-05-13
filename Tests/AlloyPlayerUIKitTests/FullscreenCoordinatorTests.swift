//
//  FullscreenCoordinatorTests.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    @testable import AlloyPlayerUIKit
    import Testing
    import UIKit

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

        @Test func fullscreenMovesSourceViewToWindowAndRestoresIt() async {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            let parentView = UIView(frame: CGRect(x: 20, y: 30, width: 200, height: 120))
            let sourceView = UIView()
            window.addSubview(parentView)
            parentView.addSubview(sourceView)
            sourceView.translatesAutoresizingMaskIntoConstraints = false
            let constraints = [
                sourceView.topAnchor.constraint(equalTo: parentView.topAnchor),
                sourceView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                sourceView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                sourceView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            ]
            NSLayoutConstraint.activate(constraints)
            window.layoutIfNeeded()

            let coordinator = FullscreenCoordinator()
            coordinator.setPresentationSourceProvider { sourceView }

            await coordinator.setFullscreen(true, animated: false)

            let fullscreenContainer = try #require(sourceView.superview)
            #expect(coordinator.state == .fullscreen)
            #expect(fullscreenContainer.superview === window)
            #expect(fullscreenContainer.frame == window.bounds)
            #expect(fullscreenContainer.transform == .identity)

            await coordinator.setFullscreen(false, animated: false)

            #expect(coordinator.state == .inline)
            #expect(sourceView.superview === parentView)
            #expect(constraints.allSatisfy(\.isActive))
        }

        @Test func fullscreenMovesSourceViewBeforeRequestingLandscapeRotation() async {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            let parentView = UIView(frame: CGRect(x: 20, y: 30, width: 200, height: 120))
            let sourceView = UIView(frame: parentView.bounds)
            window.addSubview(parentView)
            parentView.addSubview(sourceView)

            let orientationCoordinator = CapturingOrientationCoordinator {
                sourceView.superview?.superview === window
            }
            let coordinator = FullscreenCoordinator(orientationCoordinator: orientationCoordinator)
            coordinator.setPresentationSourceProvider { sourceView }

            await coordinator.setFullscreen(true, animated: false)

            #expect(orientationCoordinator.didSourceReachFullscreenContainerBeforeRotation == true)
        }

        @Test func fullscreenKeepsSourceFrameUntilRotationCompletes() async {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            let parentView = UIView(frame: CGRect(x: 20, y: 30, width: 200, height: 120))
            let sourceView = UIView(frame: parentView.bounds)
            window.addSubview(parentView)
            parentView.addSubview(sourceView)

            let orientationCoordinator = CapturingOrientationCoordinator {
                sourceView.frame == CGRect(x: 20, y: 30, width: 200, height: 120)
            }
            let coordinator = FullscreenCoordinator(orientationCoordinator: orientationCoordinator)
            coordinator.setPresentationSourceProvider { sourceView }

            await coordinator.setFullscreen(true, animated: false)

            #expect(orientationCoordinator.didSourceKeepWindowFrameBeforeRotation == true)
        }

        @Test func portraitFullscreenUsesWindowBoundsWithoutRotation() async throws {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            let parentView = UIView(frame: CGRect(x: 20, y: 30, width: 200, height: 120))
            let sourceView = UIView(frame: parentView.bounds)
            window.addSubview(parentView)
            parentView.addSubview(sourceView)

            let coordinator = FullscreenCoordinator(configuration: FullscreenConfiguration(mode: .portrait))
            coordinator.setPresentationSourceProvider { sourceView }

            await coordinator.setFullscreen(true, animated: false)

            let fullscreenContainer = try #require(sourceView.superview)
            #expect(fullscreenContainer.bounds.size == window.bounds.size)
            #expect(fullscreenContainer.transform == .identity)
        }

        @Test func orientationCoordinatorMapsModesToSystemOrientations() {
            let coordinator = InterfaceOrientationCoordinator()

            let automatic = coordinator.orientation(for: .automatic)
            let landscape = coordinator.orientation(for: .landscape)
            let portrait = coordinator.orientation(for: .portrait)

            #expect(automatic.mask == .landscapeRight)
            #expect(automatic.interfaceOrientation == .landscapeRight)
            #expect(landscape.mask == .landscapeRight)
            #expect(landscape.interfaceOrientation == .landscapeRight)
            #expect(portrait.mask == .portrait)
            #expect(portrait.interfaceOrientation == .portrait)
        }

        @Test func deviceLandscapeOrientationMapsToMatchingInterfaceOrientation() {
            #expect(UIDeviceOrientation.landscapeLeft.landscapeInterfaceOrientation == .landscapeRight)
            #expect(UIDeviceOrientation.landscapeRight.landscapeInterfaceOrientation == .landscapeLeft)
            #expect(UIDeviceOrientation.portrait.landscapeInterfaceOrientation == nil)
        }

        @Test func fullscreenConfigurationEnablesDeviceOrientationFullscreenByDefault() {
            #expect(FullscreenConfiguration().isDeviceOrientationFullscreenEnabled)
        }
    }

    @MainActor
    private final class CapturingOrientationCoordinator: InterfaceOrientationCoordinating {
        private let captureSourceContainerState: () -> Bool
        var didSourceReachFullscreenContainerBeforeRotation = false
        var didSourceKeepWindowFrameBeforeRotation = false

        init(captureSourceContainerState: @escaping () -> Bool) {
            self.captureSourceContainerState = captureSourceContainerState
        }

        func rotate(to _: FullscreenMode, in _: UIWindow?) async {
            didSourceReachFullscreenContainerBeforeRotation = captureSourceContainerState()
            didSourceKeepWindowFrameBeforeRotation = captureSourceContainerState()
        }

        func rotate(to _: UIInterfaceOrientation, in _: UIWindow?) async {}
    }
#endif
