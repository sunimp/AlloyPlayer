//
//  AlloySwiftUIPlayerView.swift
//  AlloyPlayerSwiftUI
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyAVPlayer
    import AlloyCore
    import SwiftUI

    /// SwiftUI 播放器视图。
    public struct AlloySwiftUIPlayerView<Controls: View>: View {
        /// 播放器控制器。
        public let controller: AlloyPlayerController

        /// 自定义控制层构建闭包。
        public let controls: (AlloyPlayerController) -> Controls

        /// 使用控制器和自定义控制层创建 SwiftUI 播放器视图。
        public init(
            controller: AlloyPlayerController,
            @ViewBuilder controls: @escaping (AlloyPlayerController) -> Controls
        ) {
            self.controller = controller
            self.controls = controls
        }

        /// SwiftUI 视图内容。
        public var body: some View {
            AlloyUIKitPlayerRepresentable(controller: controller, controls: controls)
        }
    }

    /// SwiftUI 播放器视图的便捷初始化入口。
    public extension AlloySwiftUIPlayerView {
        /// 创建默认播放会话并使用自定义控制层构建 SwiftUI 播放器视图。
        init(
            source: PlaybackSource? = nil,
            sessionConfiguration: PlaybackSessionConfiguration = .init(),
            engineConfiguration: AVPlaybackEngineConfiguration = .init(),
            @ViewBuilder controls: @escaping (AlloyPlayerController) -> Controls
        ) {
            self.init(
                controller: AlloyPlayerController(
                    source: source,
                    sessionConfiguration: sessionConfiguration,
                    engineConfiguration: engineConfiguration
                ),
                controls: controls
            )
        }
    }

    /// 默认控制层类型的 SwiftUI 播放器便捷初始化入口。
    public extension AlloySwiftUIPlayerView where Controls == DefaultSwiftUIControlOverlayView {
        /// 使用既有控制器和默认控制层创建 SwiftUI 播放器视图。
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

        /// 创建默认播放会话和默认控制层的 SwiftUI 播放器视图。
        init(
            source: PlaybackSource? = nil,
            sessionConfiguration: PlaybackSessionConfiguration = .init(),
            engineConfiguration: AVPlaybackEngineConfiguration = .init(),
            timeFormatterConfiguration: TimeFormatConfiguration = TimeFormatter.defaultConfiguration
        ) {
            self.init(
                source: source,
                sessionConfiguration: sessionConfiguration,
                engineConfiguration: engineConfiguration
            ) {
                DefaultSwiftUIControlOverlayView(
                    controller: $0,
                    timeFormatterConfiguration: timeFormatterConfiguration
                )
            }
        }
    }
#endif
