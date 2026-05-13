//
//  SwiftUIPlaybackProgressBar.swift
//  AlloySwiftUI
//
//  Created by Sun on 2026/5/9.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import SwiftUI

    /// 支持缓冲进度和点击跳转的 SwiftUI 播放进度条
    public struct SwiftUIPlaybackProgressBar: View {
        @ObservedObject private var state: SwiftUIControlOverlayState

        private let trackHeight: CGFloat
        private let hitHeight: CGFloat
        private let trackTintColor: Color
        private let bufferTintColor: Color
        private let progressTintColor: Color
        private let thumbTintColor: Color

        public init(
            state: SwiftUIControlOverlayState,
            trackHeight: CGFloat = 3,
            hitHeight: CGFloat = 24,
            trackTintColor: Color = Color.white.opacity(0.22),
            bufferTintColor: Color = Color.white.opacity(0.42),
            progressTintColor: Color = .white,
            thumbTintColor: Color = .white
        ) {
            self.state = state
            self.trackHeight = trackHeight
            self.hitHeight = hitHeight
            self.trackTintColor = trackTintColor
            self.bufferTintColor = bufferTintColor
            self.progressTintColor = progressTintColor
            self.thumbTintColor = thumbTintColor
        }

        public var body: some View {
            GeometryReader { proxy in
                let width = max(proxy.size.width, 1)
                let progress = CGFloat(state.progress.clampedToUnit)
                let bufferProgress = CGFloat(state.bufferProgress.clampedToUnit)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(trackTintColor)
                        .frame(height: trackHeight)

                    Capsule()
                        .fill(bufferTintColor)
                        .frame(width: width * bufferProgress, height: trackHeight)

                    Capsule()
                        .fill(progressTintColor)
                        .frame(width: width * progress, height: trackHeight)

                    Circle()
                        .fill(thumbTintColor)
                        .frame(width: 9, height: 9)
                        .offset(x: max(0, min(width - 9, width * progress - 4.5)))
                }
                .frame(maxWidth: .infinity, minHeight: hitHeight, maxHeight: hitHeight)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            seek(locationX: value.location.x, width: width)
                        }
                )
            }
            .frame(height: hitHeight)
        }

        private func seek(locationX: CGFloat, width: CGFloat) {
            guard state.canSeek else { return }
            let progress = Float(max(0, min(locationX / width, 1)))
            Task {
                await state.seek(toProgress: progress)
                state.showControls()
            }
        }
    }

    private extension Float {
        var clampedToUnit: Float {
            max(0, min(self, 1))
        }
    }
#endif
