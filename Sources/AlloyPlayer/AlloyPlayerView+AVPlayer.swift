//
//  AlloyPlayerView+AVPlayer.swift
//  AlloyPlayer
//
//  Created by Sun on 2026/5/12.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyAVPlayer
    import AlloyCore
    import AlloySwiftUI
    import SwiftUI
    import UIKit

    public extension AlloyPlayerView where Controls == DefaultSwiftUIControlOverlayView {
        init(url: URL?) {
            self.init(url: url, engineFactory: { AVPlaybackEngine() })
        }

        init(url: URL?, controller: AlloyPlayerController) {
            self.init(url: url, controller: controller, engineFactory: { AVPlaybackEngine() })
        }
    }

    public extension AlloyPlayerView {
        init(
            url: URL?,
            @ViewBuilder controls: @escaping (SwiftUIControlOverlayState) -> Controls
        ) {
            self.init(url: url, engineFactory: { AVPlaybackEngine() }, controls: controls)
        }

        init(
            url: URL?,
            controller: AlloyPlayerController,
            @ViewBuilder controls: @escaping (SwiftUIControlOverlayState) -> Controls
        ) {
            self.init(url: url, controller: controller, engineFactory: { AVPlaybackEngine() }, controls: controls)
        }
    }
#endif
