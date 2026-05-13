//
//  AlloyPlayerTests.swift
//  AlloyPlayerTests
//
//  Created by Sun on 2026/5/12.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyPlayer
    import SwiftUI
    import Testing

    @MainActor
    @Test func umbrellaModuleProvidesDefaultSessionFactory() {
        let session = AlloyPlayerFactory.makeDefaultSession()

        #expect(session.engine is AVPlaybackEngine)
        _ = AlloySwiftUIPlayerView(controller: AlloyPlayerController(session: session))
    }
#endif
