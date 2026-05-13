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

            overlay.render(state: state)

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
            overlay.render(state: PlaybackStateSnapshot(
                engine: PlaybackEngineSnapshot(playbackState: .playing, duration: 100)
            ))

            overlay.portraitPanel.slider.beginTrackInteraction(at: CGPoint(x: 160, y: 15))
            overlay.portraitPanel.slider.endTrackInteraction(at: CGPoint(x: 160, y: 15))

            #expect(actions == [.seek(50)])
        }
    }
#endif
