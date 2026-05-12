//
//  AlloyPlayerView.swift
//  AlloySwiftUIControls
//
//  Created by Sun on 2026/5/9.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyCore
    import Combine
    import SwiftUI
    import UIKit

    /// SwiftUI 原生播放器入口
    public struct AlloyPlayerView<Controls: View>: UIViewRepresentable {
        public typealias UIViewType = UIView

        private let url: URL?
        private let controller: AlloyPlayerController
        private let engineFactory: @MainActor () -> any PlaybackEngine
        private let controls: (SwiftUIControlOverlayState) -> Controls
        private var configuration: AlloyPlayerViewConfiguration

        public init(
            url: URL?,
            engineFactory: @escaping @MainActor () -> any PlaybackEngine
        ) where Controls == DefaultSwiftUIControlOverlayView {
            self.init(url: url, controller: AlloyPlayerController(), engineFactory: engineFactory)
        }

        public init(
            url: URL?,
            controller: AlloyPlayerController,
            engineFactory: @escaping @MainActor () -> any PlaybackEngine
        ) where Controls == DefaultSwiftUIControlOverlayView {
            self.url = url
            self.controller = controller
            self.engineFactory = engineFactory
            controls = { DefaultSwiftUIControlOverlayView(state: $0) }
            configuration = AlloyPlayerViewConfiguration()
        }

        public init(
            url: URL?,
            engineFactory: @escaping @MainActor () -> any PlaybackEngine,
            @ViewBuilder controls: @escaping (SwiftUIControlOverlayState) -> Controls
        ) {
            self.init(url: url, controller: AlloyPlayerController(), engineFactory: engineFactory, controls: controls)
        }

        public init(
            url: URL?,
            controller: AlloyPlayerController,
            engineFactory: @escaping @MainActor () -> any PlaybackEngine,
            @ViewBuilder controls: @escaping (SwiftUIControlOverlayState) -> Controls
        ) {
            self.url = url
            self.controller = controller
            self.engineFactory = engineFactory
            self.controls = controls
            configuration = AlloyPlayerViewConfiguration()
        }

        private init(
            url: URL?,
            controller: AlloyPlayerController,
            engineFactory: @escaping @MainActor () -> any PlaybackEngine,
            controls: @escaping (SwiftUIControlOverlayState) -> Controls,
            configuration: AlloyPlayerViewConfiguration
        ) {
            self.url = url
            self.controller = controller
            self.engineFactory = engineFactory
            self.controls = controls
            self.configuration = configuration
        }

        public func makeCoordinator() -> Coordinator {
            Coordinator(controller: controller)
        }

        public func makeUIView(context: Context) -> UIView {
            let containerView = PlayerContainerView()
            containerView.backgroundColor = .black
            containerView.windowChangeHandler = { [weak coordinator = context.coordinator] window in
                guard let coordinator, coordinator.configuration.pauseWhenDisappear else { return }
                if window == nil {
                    coordinator.player?.engine.pause()
                } else if coordinator.configuration.autoPlay {
                    coordinator.player?.engine.play()
                }
            }

            let engine = engineFactory()
            engine.shouldAutoPlay = configuration.autoPlay
            engine.scalingMode = configuration.scalingMode

            let overlay = SwiftUIControlOverlay(state: controller.state) { state in
                controls(state)
            }
            controller.state.autoHideInterval = configuration.controlAutoHideInterval
            overlay.onDoubleTap = { state in
                state.playOrPause()
            }

            let player = Player(engine: engine, containerView: containerView)
            player.controlOverlay = overlay
            player.disabledGestureTypes = configuration.disabledGestureTypes
            player.addDeviceOrientationObserver()
            configuration.configurePlayer?(player)

            context.coordinator.player = player
            context.coordinator.overlay = overlay
            context.coordinator.bind(configuration: configuration)
            controller.attach(player: player)
            context.coordinator.update(url: url, configuration: configuration)

            return containerView
        }

        public func updateUIView(_: UIView, context: Context) {
            context.coordinator.bind(configuration: configuration)
            context.coordinator.update(url: url, configuration: configuration)
        }

        public static func dismantleUIView(_: UIView, coordinator: Coordinator) {
            if coordinator.configuration.stopWhenDismantle {
                coordinator.player?.stop()
            }
            coordinator.controller.detach(player: coordinator.player)
            coordinator.player = nil
            coordinator.overlay = nil
            coordinator.cancellables.removeAll()
        }

        @MainActor
        public final class Coordinator {
            let controller: AlloyPlayerController
            var player: Player?
            var overlay: SwiftUIControlOverlay<Controls>?
            var configuration = AlloyPlayerViewConfiguration()
            var cancellables = Set<AnyCancellable>()

            private var currentURL: URL?

            init(controller: AlloyPlayerController) {
                self.controller = controller
            }

            func bind(configuration: AlloyPlayerViewConfiguration) {
                self.configuration = configuration
                cancellables.removeAll()
                player?.playbackStatePublisher
                    .sink { state in
                        configuration.onPlaybackStateChange?(state)
                    }
                    .store(in: &cancellables)
            }

            func update(url: URL?, configuration: AlloyPlayerViewConfiguration) {
                guard let player else { return }
                controller.state.autoHideInterval = configuration.controlAutoHideInterval
                player.engine.shouldAutoPlay = configuration.autoPlay
                player.engine.scalingMode = configuration.scalingMode
                player.disabledGestureTypes = configuration.disabledGestureTypes
                configuration.configurePlayer?(player)
                guard currentURL != url else { return }
                currentURL = url
                player.assetURL = url
            }
        }
    }

    public extension AlloyPlayerView {
        func autoPlay(_ autoPlay: Bool) -> Self {
            var config = configuration
            config.autoPlay = autoPlay
            return Self(url: url, controller: controller, engineFactory: engineFactory, controls: controls, configuration: config)
        }

        func scalingMode(_ scalingMode: ScalingMode) -> Self {
            var config = configuration
            config.scalingMode = scalingMode
            return Self(url: url, controller: controller, engineFactory: engineFactory, controls: controls, configuration: config)
        }

        func disabledGestures(_ types: DisableGestureTypes) -> Self {
            var config = configuration
            config.disabledGestureTypes = types
            return Self(url: url, controller: controller, engineFactory: engineFactory, controls: controls, configuration: config)
        }

        func controlAutoHideInterval(_ interval: TimeInterval) -> Self {
            var config = configuration
            config.controlAutoHideInterval = interval
            return Self(url: url, controller: controller, engineFactory: engineFactory, controls: controls, configuration: config)
        }

        func onPlaybackStateChange(_ action: @escaping (PlaybackState) -> Void) -> Self {
            var config = configuration
            config.onPlaybackStateChange = action
            return Self(url: url, controller: controller, engineFactory: engineFactory, controls: controls, configuration: config)
        }

        func pauseWhenDisappear(_ pauseWhenDisappear: Bool) -> Self {
            var config = configuration
            config.pauseWhenDisappear = pauseWhenDisappear
            return Self(url: url, controller: controller, engineFactory: engineFactory, controls: controls, configuration: config)
        }

        func configurePlayer(_ action: @escaping (Player) -> Void) -> Self {
            var config = configuration
            config.configurePlayer = action
            return Self(url: url, controller: controller, engineFactory: engineFactory, controls: controls, configuration: config)
        }
    }

    private final class PlayerContainerView: UIView {
        var windowChangeHandler: ((UIWindow?) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            windowChangeHandler?(window)
        }
    }
#endif
