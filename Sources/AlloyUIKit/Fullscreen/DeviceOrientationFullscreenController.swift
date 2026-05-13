//
//  DeviceOrientationFullscreenController.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import Combine
    import UIKit

    @MainActor
    final class DeviceOrientationFullscreenController {
        private weak var session: PlaybackSession?
        private weak var fullscreenCoordinator: FullscreenCoordinating?
        private var orientationObserver: NSObjectProtocol?
        private var stateCancellable: AnyCancellable?

        deinit {
            MainActor.assumeIsolated {
                stopObserving()
            }
        }

        func bind(session: PlaybackSession, fullscreenCoordinator: FullscreenCoordinating?) {
            self.session = session
            self.fullscreenCoordinator = fullscreenCoordinator
            stateCancellable = session.statePublisher.sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleDeviceOrientationChanged()
                }
            }
            if fullscreenCoordinator == nil {
                stopObserving()
            } else {
                startObserving()
            }
        }

        private func startObserving() {
            guard orientationObserver == nil else { return }
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            orientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: UIDevice.current,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    await self?.handleDeviceOrientationChanged()
                }
            }
        }

        private func stopObserving() {
            if let orientationObserver {
                NotificationCenter.default.removeObserver(orientationObserver)
                self.orientationObserver = nil
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
            }
        }

        private func handleDeviceOrientationChanged() async {
            guard let session,
                  let coordinator = fullscreenCoordinator as? FullscreenCoordinator,
                  coordinator.configuration.isDeviceOrientationFullscreenEnabled,
                  coordinator.configuration.mode != .portrait
            else { return }

            let deviceOrientation = UIDevice.current.orientation
            if deviceOrientation.isLandscape,
               coordinator.state == .inline,
               session.state.engine.playbackState == .playing
            {
                await coordinator.setFullscreen(true, animated: true)
            }
        }
    }
#endif
