//
//  PlaybackSessionBinder.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import Combine

    @MainActor
    final class PlaybackSessionBinder {
        private var cancellables = Set<AnyCancellable>()

        func bind(session: PlaybackSession, playerView: AlloyPlayerView) {
            cancel()

            if playerView.configuration.attachesRenderSurfaceAutomatically {
                playerView.renderHostView.attach(surface: session.engine.renderSurface)
            }

            session.statePublisher
                .sink { [weak playerView] state in
                    guard let playerView else { return }
                    if playerView.configuration.attachesRenderSurfaceAutomatically {
                        playerView.renderHostView.attach(surface: session.engine.renderSurface)
                    }
                    playerView.controlOverlay?.render(state: state)
                }
                .store(in: &cancellables)

            session.eventPublisher
                .sink { [weak playerView] event in
                    playerView?.controlOverlay?.handle(event: event)
                }
                .store(in: &cancellables)
        }

        func cancel() {
            cancellables.removeAll()
        }
    }
#endif
