//
//  FullscreenCoordinator.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import Combine
    import UIKit

    public enum FullscreenState: Equatable, Sendable {
        case inline
        case fullscreen
    }

    @MainActor
    public protocol FullscreenCoordinating: AnyObject {
        var state: FullscreenState { get }
        var statePublisher: AnyPublisher<FullscreenState, Never> { get }
        var fullscreenMode: FullscreenMode { get }
        func setFullscreen(_ isFullscreen: Bool, animated: Bool) async
        func toggle(animated: Bool) async
    }

    @MainActor
    open class FullscreenCoordinator: FullscreenCoordinating {
        private struct PresentationContext {
            weak var sourceView: UIView?
            weak var originalSuperview: UIView?
            var originalIndex: Int
            var originalFrame: CGRect
            var originalConstraints: [NSLayoutConstraint]
            var originalTranslatesAutoresizingMaskIntoConstraints: Bool
            var originalInterfaceOrientation: UIInterfaceOrientation
        }

        public private(set) var state: FullscreenState = .inline {
            didSet {
                guard state != oldValue else { return }
                stateSubject.send(state)
            }
        }

        public var statePublisher: AnyPublisher<FullscreenState, Never> {
            stateSubject.eraseToAnyPublisher()
        }

        public var configuration: FullscreenConfiguration

        public var fullscreenMode: FullscreenMode {
            configuration.mode
        }

        private let stateSubject = CurrentValueSubject<FullscreenState, Never>(.inline)
        private var presentationSourceProvider: (() -> UIView?)?
        private var presentationContext: PresentationContext?
        private var fullscreenContainerView: FullscreenContainerView?
        private var fullscreenConstraints: [NSLayoutConstraint] = []
        private var orientationObserver: NSObjectProtocol?
        private var isTransitioningFullscreen = false
        private var hasObservedLandscapeDeviceOrientationInFullscreen = false
        private let orientationCoordinator: InterfaceOrientationCoordinating

        public init(configuration: FullscreenConfiguration = .init()) {
            self.configuration = configuration
            orientationCoordinator = InterfaceOrientationCoordinator()
        }

        init(
            configuration: FullscreenConfiguration = .init(),
            orientationCoordinator: InterfaceOrientationCoordinating
        ) {
            self.configuration = configuration
            self.orientationCoordinator = orientationCoordinator
        }

        open func setFullscreen(_ isFullscreen: Bool, animated: Bool) async {
            if isFullscreen {
                await enterFullscreen(animated: animated)
            } else {
                await exitFullscreen(animated: animated)
            }
        }

        open func toggle(animated: Bool) async {
            await setFullscreen(state == .inline, animated: animated)
        }

        func setPresentationSourceProvider(_ provider: (() -> UIView?)?) {
            presentationSourceProvider = provider
        }

        private func enterFullscreen(animated: Bool) async {
            guard state == .inline,
                  !isTransitioningFullscreen,
                  let sourceView = presentationSourceProvider?(),
                  let originalSuperview = sourceView.superview,
                  let window = sourceView.window
            else { return }
            isTransitioningFullscreen = true
            defer {
                isTransitioningFullscreen = false
                hasObservedLandscapeDeviceOrientationInFullscreen = UIDevice.current.orientation.isLandscape
            }

            let containerView = FullscreenContainerView(frame: window.bounds)
            UIView.performWithoutAnimation {
                let originalFrame = sourceView.frame
                let originalFrameInWindow = sourceView.convert(sourceView.bounds, to: window)
                let originalIndex = originalSuperview.subviews.firstIndex(of: sourceView) ?? originalSuperview.subviews.count
                let originalConstraints = activeConstraintsAffecting(sourceView, until: window)
                let originalTranslatesAutoresizingMaskIntoConstraints = sourceView.translatesAutoresizingMaskIntoConstraints
                NSLayoutConstraint.deactivate(originalConstraints)

                containerView.backgroundColor = .black
                containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                window.addSubview(containerView)

                sourceView.translatesAutoresizingMaskIntoConstraints = true
                containerView.addSubview(sourceView)
                sourceView.frame = containerView.convert(originalFrameInWindow, from: window)
                containerView.layoutIfNeeded()

                presentationContext = PresentationContext(
                    sourceView: sourceView,
                    originalSuperview: originalSuperview,
                    originalIndex: originalIndex,
                    originalFrame: originalFrame,
                    originalConstraints: originalConstraints,
                    originalTranslatesAutoresizingMaskIntoConstraints: originalTranslatesAutoresizingMaskIntoConstraints,
                    originalInterfaceOrientation: originalInterfaceOrientation(for: window)
                )
                fullscreenContainerView = containerView
            }
            startDeviceOrientationObservationIfNeeded()
            await orientationCoordinator.rotate(to: configuration.mode, in: window)
            updateFullscreenContainerFrame()
            await animateTransition(animated: animated) {
                sourceView.frame = containerView.bounds
                sourceView.layoutIfNeeded()
            }
            UIView.performWithoutAnimation {
                installFullscreenConstraints(for: sourceView, in: containerView)
                state = .fullscreen
                containerView.layoutIfNeeded()
            }
        }

        private func exitFullscreen(animated: Bool) async {
            guard state == .fullscreen,
                  !isTransitioningFullscreen,
                  let context = presentationContext,
                  let sourceView = context.sourceView,
                  let originalSuperview = context.originalSuperview,
                  let containerView = fullscreenContainerView
            else { return }
            isTransitioningFullscreen = true
            defer { isTransitioningFullscreen = false }
            stopDeviceOrientationObservation()
            await orientationCoordinator.rotate(to: context.originalInterfaceOrientation, in: containerView.window)
            updateFullscreenContainerFrame()

            let targetFrame = originalSuperview.convert(context.originalFrame, to: containerView)
            UIView.performWithoutAnimation {
                NSLayoutConstraint.deactivate(self.fullscreenConstraints)
                self.fullscreenConstraints.removeAll()
                sourceView.translatesAutoresizingMaskIntoConstraints = true
                containerView.layoutIfNeeded()
            }
            await animateTransition(animated: animated) {
                sourceView.frame = targetFrame
                sourceView.layoutIfNeeded()
            }

            let restore = {
                let insertIndex = min(context.originalIndex, originalSuperview.subviews.count)
                originalSuperview.insertSubview(sourceView, at: insertIndex)
                sourceView.translatesAutoresizingMaskIntoConstraints = context.originalTranslatesAutoresizingMaskIntoConstraints
                NSLayoutConstraint.activate(context.originalConstraints)
                sourceView.frame = context.originalFrame
                originalSuperview.layoutIfNeeded()
                containerView.removeFromSuperview()
            }

            let finish = {
                UIView.performWithoutAnimation {
                    restore()
                    self.state = .inline
                }
                self.presentationContext = nil
                self.fullscreenContainerView = nil
                self.hasObservedLandscapeDeviceOrientationInFullscreen = false
            }
            finish()
        }

        private func animateTransition(animated: Bool, animations: @escaping () -> Void) async {
            guard animated else {
                UIView.performWithoutAnimation(animations)
                return
            }
            await withCheckedContinuation { continuation in
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: [.beginFromCurrentState, .curveEaseInOut, .allowUserInteraction]
                ) {
                    animations()
                } completion: { _ in
                    continuation.resume()
                }
            }
        }

        private func activeConstraintsAffecting(_ sourceView: UIView, until window: UIWindow) -> [NSLayoutConstraint] {
            var constraints: [NSLayoutConstraint] = []
            var currentView: UIView? = sourceView
            while let view = currentView {
                for constraint in view.constraints where constraint.isActive && constraint.affectsExternalLayout(of: sourceView, ownedBy: view) {
                    if !constraints.contains(where: { $0 === constraint }) {
                        constraints.append(constraint)
                    }
                }
                if view === window { break }
                currentView = view.superview
            }
            return constraints
        }

        private func updateFullscreenContainerFrame() {
            guard let fullscreenContainerView,
                  let window = fullscreenContainerView.window
            else { return }
            UIView.performWithoutAnimation {
                fullscreenContainerView.frame = window.bounds
                fullscreenContainerView.layoutIfNeeded()
            }
        }

        private func installFullscreenConstraints(for sourceView: UIView, in containerView: UIView) {
            NSLayoutConstraint.deactivate(fullscreenConstraints)
            sourceView.translatesAutoresizingMaskIntoConstraints = false
            fullscreenConstraints = [
                sourceView.topAnchor.constraint(equalTo: containerView.topAnchor),
                sourceView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                sourceView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                sourceView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ]
            NSLayoutConstraint.activate(fullscreenConstraints)
        }

        private func startDeviceOrientationObservationIfNeeded() {
            guard configuration.mode != .portrait,
                  configuration.isDeviceOrientationFullscreenEnabled,
                  orientationObserver == nil
            else { return }
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            orientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: UIDevice.current,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    await self.handleDeviceOrientationChanged()
                }
            }
        }

        private func stopDeviceOrientationObservation() {
            if let orientationObserver {
                NotificationCenter.default.removeObserver(orientationObserver)
                self.orientationObserver = nil
            }
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }

        private func handleDeviceOrientationChanged() async {
            let deviceOrientation = UIDevice.current.orientation
            if deviceOrientation.isLandscape {
                hasObservedLandscapeDeviceOrientationInFullscreen = true
                guard state == .fullscreen,
                      !isTransitioningFullscreen,
                      configuration.mode != .portrait,
                      configuration.isDeviceOrientationFullscreenEnabled,
                      let interfaceOrientation = deviceOrientation.landscapeInterfaceOrientation,
                      fullscreenContainerView?.window?.windowScene?.interfaceOrientation != interfaceOrientation
                else { return }
                await orientationCoordinator.rotate(to: interfaceOrientation, in: fullscreenContainerView?.window)
                updateFullscreenContainerFrame()
                return
            }
            guard state == .fullscreen,
                  !isTransitioningFullscreen,
                  configuration.mode != .portrait,
                  configuration.isDeviceOrientationFullscreenEnabled,
                  hasObservedLandscapeDeviceOrientationInFullscreen,
                  deviceOrientation.isPortrait
            else { return }
            await setFullscreen(false, animated: true)
        }

        private func originalInterfaceOrientation(for window: UIWindow) -> UIInterfaceOrientation {
            guard configuration.mode == .portrait else { return .portrait }
            return window.windowScene?.interfaceOrientation ?? .portrait
        }
    }

    @MainActor
    protocol InterfaceOrientationCoordinating: AnyObject {
        func rotate(to mode: FullscreenMode, in window: UIWindow?) async
        func rotate(to interfaceOrientation: UIInterfaceOrientation, in window: UIWindow?) async
    }

    @MainActor
    final class InterfaceOrientationCoordinator: InterfaceOrientationCoordinating {
        func rotate(to mode: FullscreenMode, in window: UIWindow?) async {
            await rotate(to: orientation(for: mode).interfaceOrientation, in: window)
        }

        func rotate(to interfaceOrientation: UIInterfaceOrientation, in window: UIWindow?) async {
            guard let window else { return }

            if #available(iOS 16.0, *) {
                rotateWithGeometryUpdate(to: interfaceOrientation.mask, in: window)
            } else {
                rotateWithDeviceOrientation(to: interfaceOrientation)
            }
            await waitForOrientation(interfaceOrientation, in: window)
        }

        func orientation(for mode: FullscreenMode) -> (mask: UIInterfaceOrientationMask, interfaceOrientation: UIInterfaceOrientation) {
            switch mode {
            case .automatic, .landscape:
                let orientation = UIDevice.current.orientation.landscapeInterfaceOrientation ?? .landscapeRight
                return (orientation.mask, orientation)
            case .portrait:
                return (.portrait, .portrait)
            }
        }

        @available(iOS 16.0, *)
        private func rotateWithGeometryUpdate(to mask: UIInterfaceOrientationMask, in window: UIWindow) {
            let viewController = window.rootViewController?.topPresentedViewController
            viewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            window.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in
                viewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }

        private func rotateWithDeviceOrientation(to orientation: UIInterfaceOrientation) {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }

        private func waitForOrientation(_ orientation: UIInterfaceOrientation, in window: UIWindow) async {
            guard window.windowScene != nil else { return }
            for _ in 0 ..< 30 {
                if window.windowScene?.interfaceOrientation == orientation {
                    return
                }
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
        }
    }

    private extension UIViewController {
        var topPresentedViewController: UIViewController {
            presentedViewController?.topPresentedViewController ?? self
        }
    }

    private extension UIInterfaceOrientation {
        var mask: UIInterfaceOrientationMask {
            switch self {
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            case .unknown:
                return .allButUpsideDown
            @unknown default:
                return .allButUpsideDown
            }
        }
    }

    private extension NSLayoutConstraint {
        func affectsExternalLayout(of sourceView: UIView, ownedBy owner: UIView) -> Bool {
            if owner === sourceView {
                return constrainsOwnSize(of: sourceView)
            }
            return firstItem === sourceView || secondItem === sourceView
        }

        private func constrainsOwnSize(of view: UIView) -> Bool {
            (firstItem === view && (secondItem == nil || secondItem === view)) ||
                (secondItem === view && (firstItem == nil || firstItem === view))
        }
    }

    extension UIDeviceOrientation {
        var landscapeInterfaceOrientation: UIInterfaceOrientation? {
            switch self {
            case .landscapeLeft:
                return .landscapeRight
            case .landscapeRight:
                return .landscapeLeft
            default:
                return nil
            }
        }
    }

    private final class FullscreenContainerView: UIView {
        override func layoutSubviews() {
            super.layoutSubviews()
        }
    }
#endif
