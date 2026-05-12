//
//  SwiftUIControlsDemoView.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/5/9.
//

import AlloyPlayer
import SwiftUI
import UIKit

// MARK: - SwiftUIControlsDemoView

/// SwiftUI 控制层演示
struct SwiftUIControlsDemoView: View {
    @State private var selectedIndex = 0
    @State private var playbackURL: URL?
    @State private var controlMode: SwiftUIControlMode = .defaultControls
    @StateObject private var controller = AlloyPlayerController()

    private let videos = VideoResource.allSamples

    var body: some View {
        VStack(spacing: 0) {
            playerView
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .background(Color.black)

            Picker("控制层", selection: $controlMode) {
                ForEach(SwiftUIControlMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            List(videos.indices, id: \.self) { index in
                Button {
                    selectedIndex = index
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(videos[index].coverColor))
                            .frame(width: 44, height: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(videos[index].title)
                                .font(.body)
                                .foregroundStyle(Color(uiColor: .label))
                            Text(videos[index].description)
                                .font(.footnote)
                                .foregroundStyle(Color(uiColor: .secondaryLabel))
                                .lineLimit(2)
                        }

                        Spacer()

                        if selectedIndex == index {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .task(id: selectedIndex) {
            await resolvePlaybackURL()
        }
    }

    @ViewBuilder
    private var playerView: some View {
        switch controlMode {
        case .defaultControls:
            AlloyPlayerView(url: playbackURL, controller: controller)
                .scalingMode(.aspectFit)
        case .customControls:
            AlloyPlayerView(url: playbackURL, controller: controller) { state in
                CustomSwiftUIPlayerControls(video: videos[selectedIndex], state: state)
            }
            .scalingMode(.aspectFit)
        }
    }

    @MainActor
    private func resolvePlaybackURL() async {
        let originalURL = videos[selectedIndex].url
        do {
            playbackURL = try await DemoPlaybackConfiguration.shared.playbackURL(for: originalURL)
        } catch {
            playbackURL = originalURL
        }
    }
}

// MARK: - SwiftUIControlMode

private enum SwiftUIControlMode: CaseIterable, Identifiable {
    case defaultControls
    case customControls

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .defaultControls: return "默认控制层"
        case .customControls: return "自定义控制层"
        }
    }
}

// MARK: - CustomSwiftUIPlayerControls

private struct CustomSwiftUIPlayerControls: View {
    let video: VideoItem
    @ObservedObject var state: SwiftUIControlOverlayState

    var body: some View {
        ZStack {
            if state.isControlVisible {
                LinearGradient(
                    colors: [Color.black.opacity(0.65), .clear, Color.black.opacity(0.75)],
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
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(state.playbackStateText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }

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

                Text(timeText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                Button {
                    Task { await state.seek(toProgress: max(0, state.progress - 0.1)) }
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)

                Button {
                    Task { await state.seek(toProgress: min(1, state.progress + 0.1)) }
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var playButtonImageName: String {
        if state.didPlayToEnd {
            return "arrow.counterclockwise"
        }
        return state.playbackState == .playing ? "pause.fill" : "play.fill"
    }

    private var timeText: String {
        "\(state.currentTimeText) / \(state.totalTimeText)"
    }
}
