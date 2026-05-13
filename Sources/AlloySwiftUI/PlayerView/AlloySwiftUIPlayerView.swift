//
//  AlloySwiftUIPlayerView.swift
//  AlloySwiftUI
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyCore
    import SwiftUI

    /// SwiftUI 播放器视图。
    public struct AlloySwiftUIPlayerView<Controls: View>: View {
        public let controller: AlloyPlayerController
        public let controls: (AlloyPlayerController) -> Controls

        public init(
            controller: AlloyPlayerController,
            @ViewBuilder controls: @escaping (AlloyPlayerController) -> Controls
        ) {
            self.controller = controller
            self.controls = controls
        }

        public var body: some View {
            AlloyUIKitPlayerRepresentable(controller: controller, controls: controls)
        }
    }

    public extension AlloySwiftUIPlayerView where Controls == DefaultSwiftUIControlOverlayView {
        init(
            controller: AlloyPlayerController,
            timeFormatterConfiguration: TimeFormatConfiguration = TimeFormatter.defaultConfiguration
        ) {
            self.init(controller: controller) {
                DefaultSwiftUIControlOverlayView(
                    controller: $0,
                    timeFormatterConfiguration: timeFormatterConfiguration
                )
            }
        }
    }
#endif
