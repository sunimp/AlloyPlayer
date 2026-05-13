//
//  ControlOverlayTests.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    @testable import AlloyUIKit
    import Testing
    import UIKit

    @MainActor
    @Suite("Control Overlay Tests")
    struct ControlOverlayTests {
        @Test func defaultOverlayRendersPlaybackState() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
            let state = PlaybackStateSnapshot(
                engine: PlaybackEngineSnapshot(playbackState: .playing, loadState: .playable, duration: 100)
            )

            overlay.render(context: PlaybackControlContext(state: state))

            #expect(overlay.portraitPanel.playPauseButton.isHidden == false)
        }

        @Test func defaultOverlayAllowsFailureRetryTitleConfiguration() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 320, height: 180))

            overlay.failureRetryTitle = "Retry"

            #expect(overlay.failButton.title(for: .normal) == "Retry")
        }

        @Test func defaultOverlayPropagatesTimePlaceholderConfiguration() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 320, height: 180))

            overlay.timeFormatterConfiguration = TimeFormatConfiguration(zeroPlaceholder: "--:--")
            overlay.resetControlView()

            #expect(overlay.portraitPanel.currentTimeLabel.text == "--:--")
            #expect(overlay.landscapePanel.totalTimeLabel.text == "--:--")
        }

        @Test func sliderSeekDoesNotResumePlaybackByDefault() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
            var actions: [PlaybackControlAction] = []
            overlay.actionHandler = { actions.append($0) }
            overlay.render(context: PlaybackControlContext(state: PlaybackStateSnapshot(
                engine: PlaybackEngineSnapshot(playbackState: .playing, duration: 100)
            )))

            overlay.portraitPanel.slider.beginTrackInteraction(at: CGPoint(x: 160, y: 15))
            overlay.portraitPanel.slider.endTrackInteraction(at: CGPoint(x: 160, y: 15))

            #expect(actions == [.seek(50)])
        }

        @Test func endedPlayButtonSendsReplayAction() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
            var actions: [PlaybackControlAction] = []
            overlay.actionHandler = { actions.append($0) }
            overlay.render(context: PlaybackControlContext(state: PlaybackStateSnapshot(
                engine: PlaybackEngineSnapshot(playbackState: .ended, currentTime: 100, duration: 100)
            )))

            overlay.portraitPanel.playPauseButton.sendActions(for: .touchUpInside)

            #expect(actions == [.replay])
        }

        @Test func portraitPanelHidesGradientsWithToolbars() {
            let panel = PortraitControlPanel(frame: CGRect(x: 0, y: 0, width: 320, height: 180))

            panel.showControlView()
            panel.hideControlView()

            #expect(panel.topToolBar.superview === panel.topGradientView)
            #expect(panel.bottomToolBar.superview === panel.bottomGradientView)
            #expect(panel.topGradientView.alpha == 0)
            #expect(panel.bottomGradientView.alpha == 0)
        }

        @Test func lockingLandscapeOverlayImmediatelyHidesVisibleToolbars() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 640, height: 360))
            overlay.render(context: PlaybackControlContext(
                state: PlaybackStateSnapshot(engine: PlaybackEngineSnapshot()),
                fullscreenState: .fullscreen,
                fullscreenMode: .landscape,
                layout: .fullscreenLandscape
            ))
            overlay.show(title: nil, fullScreenMode: .landscape)

            overlay.landscapePanel.lockButton.sendActions(for: .touchUpInside)

            #expect(overlay.landscapePanel.isLocked)
            #expect(overlay.landscapePanel.lockButton.isSelected)
            #expect(!overlay.isControlViewVisible)
            #expect(overlay.landscapePanel.topToolBar.superview === overlay.landscapePanel.topGradientView)
            #expect(overlay.landscapePanel.bottomToolBar.superview === overlay.landscapePanel.bottomGradientView)
            #expect(overlay.landscapePanel.topGradientView.alpha == 0)
            #expect(overlay.landscapePanel.bottomGradientView.alpha == 0)
            #expect(overlay.landscapePanel.lockButton.alpha == 1)
            #expect(overlay.bottomProgress.isHidden)
        }

        @Test func unlockingLandscapeOverlayShowsControlPanel() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 640, height: 360))
            overlay.render(context: PlaybackControlContext(
                state: PlaybackStateSnapshot(engine: PlaybackEngineSnapshot()),
                fullscreenState: .fullscreen,
                fullscreenMode: .landscape,
                layout: .fullscreenLandscape
            ))
            overlay.show(title: nil, fullScreenMode: .landscape)

            overlay.landscapePanel.lockButton.sendActions(for: .touchUpInside)
            overlay.landscapePanel.lockButton.sendActions(for: .touchUpInside)

            #expect(!overlay.landscapePanel.isLocked)
            #expect(overlay.isControlViewVisible)
            #expect(overlay.landscapePanel.topGradientView.alpha == 1)
            #expect(overlay.landscapePanel.bottomGradientView.alpha == 1)
        }

        @Test func layoutChangeShowsControlPanelOnce() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 640, height: 360))
            overlay.autoHideInterval = 0
            let state = PlaybackStateSnapshot(engine: PlaybackEngineSnapshot())

            overlay.render(context: PlaybackControlContext(
                state: state,
                fullscreenState: .inline,
                fullscreenMode: .automatic,
                layout: .inline
            ))
            overlay.handle(input: .gesture(.singleTap))
            overlay.handle(input: .gesture(.singleTap))

            #expect(!overlay.isControlViewVisible)

            overlay.render(context: PlaybackControlContext(
                state: state,
                fullscreenState: .fullscreen,
                fullscreenMode: .landscape,
                layout: .fullscreenLandscape
            ))

            #expect(overlay.isControlViewVisible)
            #expect(overlay.landscapePanel.topGradientView.alpha == 1)
        }

        @Test func defaultOverlayUsesContextLayoutForFullscreenPanels() {
            let overlay = DefaultControlOverlay(frame: CGRect(x: 0, y: 0, width: 640, height: 360))
            let state = PlaybackStateSnapshot(engine: PlaybackEngineSnapshot())

            overlay.render(context: PlaybackControlContext(
                state: state,
                fullscreenState: .fullscreen,
                fullscreenMode: .landscape,
                layout: .fullscreenLandscape
            ))

            #expect(overlay.portraitPanel.isHidden)
            #expect(!overlay.landscapePanel.isHidden)

            overlay.render(context: PlaybackControlContext(
                state: state,
                fullscreenState: .fullscreen,
                fullscreenMode: .portrait,
                layout: .fullscreenPortrait
            ))

            #expect(!overlay.portraitPanel.isHidden)
            #expect(overlay.landscapePanel.isHidden)
        }
    }
#endif
