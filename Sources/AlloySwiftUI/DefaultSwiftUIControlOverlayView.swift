//
//  DefaultSwiftUIControlOverlayView.swift
//  AlloySwiftUI
//
//  Created by Sun on 2026/5/9.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import SwiftUI

    /// 开箱即用的 SwiftUI 控制层
    public struct DefaultSwiftUIControlOverlayView: View {
        @ObservedObject private var state: SwiftUIControlOverlayState

        public init(state: SwiftUIControlOverlayState) {
            self.state = state
        }

        public var body: some View {
            ZStack {
                if state.isControlVisible {
                    LinearGradient(
                        colors: [Color.black.opacity(0.65), .clear, Color.black.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack(spacing: 0) {
                        topBar
                        Spacer()
                        bottomBar
                    }
                    .padding(14)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: state.isControlVisible)
        }

        private var topBar: some View {
            HStack(spacing: 10) {
                Text(state.playbackStateText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Button {
                    Task { await state.enterFullScreen(!state.isFullScreen) }
                } label: {
                    Image(systemName: state.isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.16), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }

        private var bottomBar: some View {
            VStack(spacing: 10) {
                SwiftUIPlaybackProgressBar(state: state)

                HStack(spacing: 12) {
                    Button {
                        state.playOrPause()
                    } label: {
                        Image(systemName: playButtonImageName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.16), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Text("\(state.currentTimeText) / \(state.totalTimeText)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.85))

                    Spacer()

                    if state.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
        }

        private var playButtonImageName: String {
            if state.didPlayToEnd {
                return "arrow.counterclockwise"
            }
            return state.isPlaying ? "pause.fill" : "play.fill"
        }
    }
#endif
