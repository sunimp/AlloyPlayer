//
//  AlloySwiftUIPlayerViewTests.swift
//  AlloyPlayerSwiftUITests
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyCore
    @testable import AlloyPlayerSwiftUI
    import Combine
    import Foundation
    import SwiftUI
    import Testing

    @MainActor
    @Test func swiftUIPlayerViewInitializesWithDefaultControls() throws {
        let controller = AlloyPlayerController(session: PlaybackSession(engine: ViewTestEngine()))
        _ = AlloySwiftUIPlayerView(controller: controller)
        _ = try AlloySwiftUIPlayerView(source: PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4"))))
        _ = AlloySwiftUIPlayerView(
            controller: controller,
            timeFormatterConfiguration: TimeFormatConfiguration(zeroPlaceholder: "--:--")
        )
        _ = AlloySwiftUIPlayerView(controller: controller) { controller in
            DefaultSwiftUIControlOverlayView(controller: controller)
        }
        _ = try AlloySwiftUIPlayerView(source: PlaybackSource(url: #require(URL(string: "https://example.invalid/video.mp4")))) { controller in
            DefaultSwiftUIControlOverlayView(controller: controller)
        }
        _ = DefaultSwiftUIControlOverlayView(
            controller: controller,
            timeFormatterConfiguration: TimeFormatConfiguration(zeroPlaceholder: "--:--")
        )
    }

    @MainActor
    private final class ViewTestEngine: PlaybackEngine {
        private let snapshotSubject = CurrentValueSubject<PlaybackEngineSnapshot, Never>(PlaybackEngineSnapshot())

        var snapshot: PlaybackEngineSnapshot {
            snapshotSubject.value
        }

        var snapshotPublisher: AnyPublisher<PlaybackEngineSnapshot, Never> {
            snapshotSubject.eraseToAnyPublisher()
        }

        func play() {}
        func pause() {}
        func stop() {}
        func seek(to _: TimeInterval) async -> Bool {
            true
        }
    }
#endif
