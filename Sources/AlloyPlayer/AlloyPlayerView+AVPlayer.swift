//
//  AlloyPlayerView+AVPlayer.swift
//  AlloyPlayer
//
//  Created by Sun on 2026/5/12.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyAVPlayer
    import AlloyCore
    import AlloySwiftUIControls
    import SwiftUI
    import UIKit

    public extension AlloyPlayerView where Controls == DefaultSwiftUIControlOverlayView {
        init(url: URL?) {
            self.init(url: url, engineFactory: { AVPlayerManager() })
        }

        init(url: URL?, controller: AlloyPlayerController) {
            self.init(url: url, controller: controller, engineFactory: { AVPlayerManager() })
        }
    }

    public extension AlloyPlayerView {
        init(
            url: URL?,
            @ViewBuilder controls: @escaping (SwiftUIControlOverlayState) -> Controls
        ) {
            self.init(url: url, engineFactory: { AVPlayerManager() }, controls: controls)
        }

        init(
            url: URL?,
            controller: AlloyPlayerController,
            @ViewBuilder controls: @escaping (SwiftUIControlOverlayState) -> Controls
        ) {
            self.init(url: url, controller: controller, engineFactory: { AVPlayerManager() }, controls: controls)
        }
    }
#endif
