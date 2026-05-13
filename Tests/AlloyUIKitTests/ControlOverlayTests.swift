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
    }
#endif
