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
    @State private var controlMode: SwiftUIControlMode = .defaultControls
    @StateObject private var controller = AlloyPlayerController(
        session: AlloyPlayerFactory.makeDefaultSession()
    )

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
            AlloySwiftUIPlayerView(controller: controller)
        case .customControls:
            AlloySwiftUIPlayerView(controller: controller) { controller in
                CustomSwiftUIPlayerControls(video: videos[selectedIndex], controller: controller)
            }
        }
    }

    @MainActor
    private func resolvePlaybackURL() async {
        let originalURL = videos[selectedIndex].url
        do {
            let source = try await DemoPlaybackConfiguration.shared.playbackSource(for: originalURL)
            controller.load(source)
        } catch {
            controller.load(PlaybackSource(url: originalURL))
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
    @ObservedObject var controller: AlloyPlayerController
    @State private var isControlVisible = true

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isControlVisible.toggle()
                    }
                }

            if isControlVisible {
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
        .animation(.easeInOut(duration: 0.2), value: isControlVisible)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(playbackStateText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            ProgressView(value: progress)
                .tint(.white)

            HStack(spacing: 12) {
                Button {
                    controller.state.engine.playbackState == .playing ? controller.pause() : controller.play()
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
                    Task { await seek(to: max(0, progress - 0.1)) }
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)

                Button {
                    Task { await seek(to: min(1, progress + 0.1)) }
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
        if controller.state.engine.playbackState == .ended {
            return "arrow.counterclockwise"
        }
        return controller.state.engine.playbackState == .playing ? "pause.fill" : "play.fill"
    }

    private var timeText: String {
        "\(format(controller.state.engine.currentTime)) / \(format(controller.state.engine.duration))"
    }

    private var progress: Double {
        let engine = controller.state.engine
        guard engine.duration > 0 else { return 0 }
        return min(max(engine.currentTime / engine.duration, 0), 1)
    }

    private var playbackStateText: String {
        switch controller.state.engine.playbackState {
        case .idle: return "空闲"
        case .loading: return "加载中"
        case .ready: return "就绪"
        case .playing: return "播放中"
        case .paused: return "已暂停"
        case .seeking: return "跳转中"
        case .buffering: return "缓冲中"
        case .ended: return "已结束"
        case .failed: return "失败"
        case .stopped: return "已停止"
        }
    }

    private func seek(to progress: Double) async {
        let duration = controller.state.engine.duration
        guard duration > 0 else { return }
        _ = await controller.seek(to: duration * progress)
        controller.play()
    }

    private func format(_ time: TimeInterval) -> String {
        let seconds = max(Int(time), 0)
        if seconds < 3600 {
            return String(format: "%02d:%02d", seconds / 60, seconds % 60)
        }
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}
