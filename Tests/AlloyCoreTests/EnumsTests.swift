//
//  EnumsTests.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

@testable import AlloyCore
import Testing

@Suite("Enums & OptionSet Tests")
struct EnumsTests {
    @Test func playbackStateRawValues() {
        #expect(PlaybackState.unknown.rawValue == 0)
        #expect(PlaybackState.playing.rawValue == 1)
        #expect(PlaybackState.paused.rawValue == 2)
        #expect(PlaybackState.failed.rawValue == 3)
        #expect(PlaybackState.stopped.rawValue == 4)
    }

    @Test func loadStateOptionSet() {
        let state: LoadState = [.prepare, .playable]
        #expect(state.contains(.prepare))
        #expect(state.contains(.playable))
        #expect(!state.contains(.stalled))
    }

    @Test func disableGestureTypesAll() {
        let all: DisableGestureTypes = .all
        #expect(all.contains(.singleTap))
        #expect(all.contains(.doubleTap))
        #expect(all.contains(.pan))
        #expect(all.contains(.pinch))
        #expect(all.contains(.longPress))
    }

    @Test func interfaceOrientationMaskComposites() {
        let landscape: InterfaceOrientationMask = .landscape
        #expect(landscape.contains(.landscapeLeft))
        #expect(landscape.contains(.landscapeRight))
        #expect(!landscape.contains(.portrait))

        let allButUpsideDown: InterfaceOrientationMask = .allButUpsideDown
        #expect(allButUpsideDown.contains(.portrait))
        #expect(allButUpsideDown.contains(.landscapeLeft))
        #expect(allButUpsideDown.contains(.landscapeRight))
        #expect(!allButUpsideDown.contains(.portraitUpsideDown))
    }

    @Test func reachabilityStatusRawValues() {
        #expect(ReachabilityStatus.unknown.rawValue == -1)
        #expect(ReachabilityStatus.notReachable.rawValue == 0)
        #expect(ReachabilityStatus.wifi.rawValue == 1)
        #expect(ReachabilityStatus.cellular5G.rawValue == 5)
    }

    @Test func scrollAnchorValues() {
        #expect(ScrollAnchor.none.rawValue == 0)
        #expect(ScrollAnchor.top.rawValue == 1)
        #expect(ScrollAnchor.centeredVertically.rawValue == 2)
        #expect(ScrollAnchor.bottom.rawValue == 3)
    }

    @Test func disablePanMovingDirectionAll() {
        let all: DisablePanMovingDirection = .all
        #expect(all.contains(.vertical))
        #expect(all.contains(.horizontal))
    }

    @Test func disablePortraitGestureTypesAll() {
        let all: DisablePortraitGestureTypes = .all
        #expect(all.contains(.tap))
        #expect(all.contains(.pan))
    }
}
