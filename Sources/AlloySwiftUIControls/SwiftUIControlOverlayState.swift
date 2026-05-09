//
//  SwiftUIControlOverlayState.swift
//  AlloySwiftUIControls
//
//  Created by Sun on 2026/5/9.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyCore
    import Combine
    import CoreGraphics
    import Foundation
    import UIKit

    /// SwiftUI 控制层可观察状态与播放器动作入口
    @MainActor
    public final class SwiftUIControlOverlayState: ObservableObject {
        public private(set) weak var player: Player?

        @Published public private(set) var activeURL: URL?
        @Published public private(set) var playbackState: PlaybackState = .unknown
        @Published public private(set) var loadState: LoadState = .unknown
        @Published public private(set) var currentTime: TimeInterval = 0
        @Published public private(set) var totalTime: TimeInterval = 0
        @Published public private(set) var bufferTime: TimeInterval = 0
        @Published public private(set) var isFullScreen = false
        @Published public private(set) var isScreenLocked = false
        @Published public private(set) var reachabilityStatus: ReachabilityStatus = .unknown
        @Published public private(set) var presentationSize: CGSize = .zero
        @Published public private(set) var lastError: (any Error)?
        @Published public private(set) var didPlayToEnd = false
        @Published public private(set) var lastGestureType: GestureType = .unknown
        @Published public private(set) var isFloatingViewVisible = false
        @Published public private(set) var isControlVisible = true

        public var autoHideInterval: TimeInterval = 2.5 {
            didSet {
                guard isControlVisible else { return }
                scheduleAutoHide()
            }
        }

        private var autoHideWorkItem: DispatchWorkItem?

        /// 播放进度，范围 0...1
        public var progress: Float {
            guard totalTime > 0 else { return 0 }
            return Float(currentTime / totalTime)
        }

        /// 缓冲进度，范围 0...1
        public var bufferProgress: Float {
            guard totalTime > 0 else { return 0 }
            return Float(bufferTime / totalTime)
        }

        /// 是否正在播放
        public var isPlaying: Bool {
            playbackState == .playing
        }

        /// 是否正在加载或缓冲
        public var isLoading: Bool {
            loadState.contains(.prepare) || loadState.contains(.stalled)
        }

        /// 是否播放失败
        public var isFailed: Bool {
            playbackState == .failed || lastError != nil
        }

        /// 是否可跳转
        public var canSeek: Bool {
            totalTime > 0
        }

        /// 当前播放时间文本
        public var currentTimeText: String {
            TimeFormatter.string(from: Int(currentTime))
        }

        /// 总时长文本
        public var totalTimeText: String {
            TimeFormatter.string(from: Int(totalTime))
        }

        /// 播放状态文本
        public var playbackStateText: String {
            switch playbackState {
            case .unknown: return "未知"
            case .playing: return "播放中"
            case .paused: return "已暂停"
            case .failed: return "播放失败"
            case .stopped: return didPlayToEnd ? "播放完成" : "已停止"
            }
        }

        public init() {}

        public func play() {
            player?.engine.play()
            scheduleAutoHide()
        }

        public func pause() {
            player?.engine.pause()
            scheduleAutoHide()
        }

        public func playOrPause() {
            guard let player else { return }
            if player.engine.isPlaying {
                player.engine.pause()
            } else {
                player.engine.play()
            }
        }

        public func replay() {
            player?.engine.replay()
            scheduleAutoHide()
        }

        @discardableResult
        public func seek(to time: TimeInterval) async -> Bool {
            guard let player else { return false }
            return await player.seek(to: time)
        }

        @discardableResult
        public func seek(toProgress progress: Float) async -> Bool {
            guard let player, player.totalTime > 0 else { return false }
            let clampedProgress = max(0, min(progress, 1))
            return await player.seek(to: player.totalTime * TimeInterval(clampedProgress))
        }

        public func enterFullScreen(_ fullScreen: Bool, animated: Bool = true) async {
            await player?.enterFullScreen(fullScreen, animated: animated)
            scheduleAutoHide()
        }

        public func setScreenLocked(_ isLocked: Bool) {
            player?.isScreenLocked = isLocked
        }

        public func showControls() {
            isControlVisible = true
            scheduleAutoHide()
        }

        public func hideControls() {
            isControlVisible = false
            cancelAutoHide()
        }

        public func toggleControls() {
            if isControlVisible {
                hideControls()
            } else {
                showControls()
            }
        }

        func attach(player: Player?) {
            self.player = player
            isFullScreen = player?.isFullScreen ?? false
            isScreenLocked = player?.isScreenLocked ?? false
            if player == nil {
                cancelAutoHide()
            } else if isControlVisible {
                scheduleAutoHide()
            }
        }

        func updatePrepareToPlay(url: URL) {
            activeURL = url
            didPlayToEnd = false
            lastError = nil
            showControls()
        }

        func updatePlaybackState(_ state: PlaybackState) {
            playbackState = state
        }

        func updateLoadState(_ state: LoadState) {
            loadState = state
        }

        func updateTime(current: TimeInterval, total: TimeInterval) {
            currentTime = current
            totalTime = total
        }

        func updateBufferTime(_ time: TimeInterval) {
            bufferTime = time
        }

        func updatePlayToEnd() {
            didPlayToEnd = true
            showControls()
        }

        func updateError(_ error: any Error) {
            lastError = error
            showControls()
        }

        func updateLockState(_ isLocked: Bool) {
            isScreenLocked = isLocked
        }

        func updateOrientation(player: Player) {
            isFullScreen = player.isFullScreen
        }

        func updateReachability(_ status: ReachabilityStatus) {
            reachabilityStatus = status
        }

        func updatePresentationSize(_ size: CGSize) {
            presentationSize = size
        }

        func updateGesture(_ type: GestureType) {
            lastGestureType = type
        }

        func updateFloatingViewVisible(_ isVisible: Bool) {
            isFloatingViewVisible = isVisible
        }

        private func scheduleAutoHide() {
            cancelAutoHide()
            guard autoHideInterval > 0 else { return }
            let workItem = DispatchWorkItem { [weak self] in
                Task { @MainActor in
                    self?.hideControls()
                }
            }
            autoHideWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + autoHideInterval, execute: workItem)
        }

        private func cancelAutoHide() {
            autoHideWorkItem?.cancel()
            autoHideWorkItem = nil
        }
    }
#endif
