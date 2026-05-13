//
//  DefaultSwiftUIControlOverlayView.swift
//  AlloySwiftUI
//
//  Created by Sun on 2026/5/13.
//

#if canImport(SwiftUI)
    import AlloyCore
    import SwiftUI

    /// 默认 SwiftUI 控制层。
    public struct DefaultSwiftUIControlOverlayView: View {
        @ObservedObject private var controller: AlloyPlayerController
        private let timeFormatterConfiguration: TimeFormatConfiguration

        public init(
            controller: AlloyPlayerController,
            timeFormatterConfiguration: TimeFormatConfiguration = TimeFormatter.defaultConfiguration
        ) {
            self.controller = controller
            self.timeFormatterConfiguration = timeFormatterConfiguration
        }

        public var body: some View {
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        controller.state.engine.playbackState == .playing ? controller.pause() : controller.play()
                    } label: {
                        Image(systemName: controller.state.engine.playbackState == .playing ? "pause.fill" : "play.fill")
                            .frame(width: 32, height: 32)
                    }

                    ProgressView(value: progress)
                        .tint(.white)

                    Text(timeText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(minWidth: 88, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.black.opacity(0.45))
            }
            .foregroundStyle(.white)
        }

        private var progress: Double {
            let engine = controller.state.engine
            guard engine.duration > 0 else { return 0 }
            return min(max(engine.currentTime / engine.duration, 0), 1)
        }

        private var timeText: String {
            let engine = controller.state.engine
            let current = TimeFormatter.string(from: Int(engine.currentTime), configuration: timeFormatterConfiguration)
            let duration = TimeFormatter.string(from: Int(engine.duration), configuration: timeFormatterConfiguration)
            return "\(current) / \(duration)"
        }
    }
#endif
