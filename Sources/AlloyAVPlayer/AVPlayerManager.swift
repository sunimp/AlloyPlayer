//
//  AVPlayerManager.swift
//  AlloyAVPlayer
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import AlloyCore
    import AVFoundation
    import Combine
    import UIKit

    /// AVPlayer 播放引擎
    ///
    /// 基于 AVFoundation 实现的 `PlaybackEngine`，是框架内置的默认播放引擎。
    @MainActor
    public final class AVPlayerManager: PlaybackEngine {
        // MARK: - AVFoundation 对象

        public private(set) var asset: AVURLAsset?
        public private(set) var playerItem: AVPlayerItem?
        public private(set) var player: AVPlayer?
        public private(set) var playerLayer: AVPlayerLayer?

        // MARK: - 配置

        /// 时间刷新间隔（默认 0.1s）
        public var timeRefreshInterval: TimeInterval = 0.1

        /// 自定义请求头
        public var requestHeaders: [String: String]?

        // MARK: - PlaybackEngine 属性

        public let renderView = RenderView()

        public private(set) var playbackState: PlaybackState = .unknown {
            didSet { if playbackState != oldValue { _state.send(playbackState) } }
        }

        public private(set) var loadState: LoadState = .unknown {
            didSet { if loadState != oldValue { _loadState.send(loadState) } }
        }

        public var isPlaying: Bool {
            playbackState == .playing
        }

        public private(set) var isPreparedToPlay = false

        public var volume: Float {
            get { player?.volume ?? 0 }
            set { player?.volume = newValue }
        }

        public var isMuted: Bool {
            get { player?.isMuted ?? false }
            set { player?.isMuted = newValue }
        }

        public var rate: Float {
            get { player?.rate ?? 1 }
            set { player?.rate = newValue }
        }

        public var scalingMode: ScalingMode = .aspectFit {
            didSet { updateVideoGravity() }
        }

        public var shouldAutoPlay = true

        public private(set) var currentTime: TimeInterval = 0
        public private(set) var totalTime: TimeInterval = 0
        public private(set) var bufferTime: TimeInterval = 0
        public var seekTime: TimeInterval = 0

        public var assetURL: URL? {
            didSet {
                if assetURL != oldValue {
                    stop()
                    if assetURL != nil { prepareToPlay() }
                }
            }
        }

        public private(set) var presentationSize: CGSize = .zero {
            didSet { if presentationSize != oldValue { _presentationSize.send(presentationSize) } }
        }

        // MARK: - Combine Subjects

        private let _state = PassthroughSubject<PlaybackState, Never>()
        private let _loadState = PassthroughSubject<LoadState, Never>()
        private let _playTime = PassthroughSubject<(current: TimeInterval, total: TimeInterval), Never>()
        private let _bufferTime = PassthroughSubject<TimeInterval, Never>()
        private let _prepareToPlay = PassthroughSubject<URL, Never>()
        private let _readyToPlay = PassthroughSubject<URL, Never>()
        private let _playFailed = PassthroughSubject<any Error, Never>()
        private let _didPlayToEnd = PassthroughSubject<Void, Never>()
        private let _presentationSize = PassthroughSubject<CGSize, Never>()

        // MARK: - Combine 事件流

        public var statePublisher: AnyPublisher<PlaybackState, Never> {
            _state.eraseToAnyPublisher()
        }

        public var loadStatePublisher: AnyPublisher<LoadState, Never> {
            _loadState.eraseToAnyPublisher()
        }

        public var playTimePublisher: AnyPublisher<(current: TimeInterval, total: TimeInterval), Never> {
            _playTime.eraseToAnyPublisher()
        }

        public var bufferTimePublisher: AnyPublisher<TimeInterval, Never> {
            _bufferTime.eraseToAnyPublisher()
        }

        public var prepareToPlayPublisher: AnyPublisher<URL, Never> {
            _prepareToPlay.eraseToAnyPublisher()
        }

        public var readyToPlayPublisher: AnyPublisher<URL, Never> {
            _readyToPlay.eraseToAnyPublisher()
        }

        public var playFailedPublisher: AnyPublisher<any Error, Never> {
            _playFailed.eraseToAnyPublisher()
        }

        public var didPlayToEndPublisher: AnyPublisher<Void, Never> {
            _didPlayToEnd.eraseToAnyPublisher()
        }

        public var presentationSizePublisher: AnyPublisher<CGSize, Never> {
            _presentationSize.eraseToAnyPublisher()
        }

        // MARK: - 内部状态

        private var kvoManager = KVOManager()
        private var timeObserver: Any?
        private var endObserver: NSObjectProtocol?
        private var isBuffering = false
        private var isReadyToPlay = false

        // MARK: - 初始化

        public init() {}

        deinit {
            MainActor.assumeIsolated {
                stop()
            }
        }

        // MARK: - PlaybackEngine 方法

        public func prepareToPlay() {
            guard let url = assetURL else { return }
            initializePlayer(url: url)
        }

        public func reloadPlayer() {
            guard let url = assetURL else { return }
            stop()
            assetURL = url
        }

        public func play() {
            guard isPreparedToPlay else { return }
            // 播放结束后 AVPlayer 的 currentTime 会停留在 duration，
            // 此时直接调用 play() 无效，必须先 seek 回 0
            if isAtEnd {
                replay()
                return
            }
            player?.play()
            player?.rate = rate
            playbackState = .playing
        }

        /// 当前播放位置是否已到达（或超过）媒体末尾
        private var isAtEnd: Bool {
            guard let item = playerItem else { return false }
            let duration = item.duration
            guard duration.isValid, !duration.isIndefinite, duration.seconds > 0 else { return false }
            return CMTimeCompare(item.currentTime(), duration) >= 0
        }

        public func pause() {
            player?.pause()
            playbackState = .paused
        }

        public func replay() {
            seekTime = 0
            Task {
                _ = await seek(to: 0)
                play()
            }
        }

        public func stop() {
            kvoManager.invalidate()
            removeTimeObserver()
            removeEndObserver()

            player?.pause()
            player?.replaceCurrentItem(with: nil)
            playerLayer?.removeFromSuperlayer()

            player = nil
            playerItem = nil
            asset = nil
            playerLayer = nil

            isPreparedToPlay = false
            isBuffering = false
            isReadyToPlay = false
            currentTime = 0
            totalTime = 0
            bufferTime = 0
            playbackState = .stopped
            loadState = .unknown
        }

        public func seek(to time: TimeInterval) async -> Bool {
            guard let player, let item = playerItem else { return false }
            let timescale = item.asset.duration.timescale
            let cmTime = CMTime(seconds: time, preferredTimescale: timescale)

            return await withCheckedContinuation { continuation in
                player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
                    continuation.resume(returning: finished)
                }
            }
        }

        public func thumbnailImageAtCurrentTime() -> UIImage? {
            guard let asset else { return nil }
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            let time = CMTime(seconds: currentTime, preferredTimescale: 600)
            guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
            return UIImage(cgImage: cgImage)
        }

        // MARK: - 内部方法

        private func initializePlayer(url: URL) {
            var options: [String: Any]?
            if let headers = requestHeaders {
                options = ["AVURLAssetHTTPHeaderFieldsKey": headers]
            }

            let newAsset = AVURLAsset(url: url, options: options)
            asset = newAsset

            let newItem = AVPlayerItem(asset: newAsset)
            newItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
            playerItem = newItem

            let newPlayer: AVPlayer
            if let existing = player {
                existing.replaceCurrentItem(with: newItem)
                newPlayer = existing
            } else {
                newPlayer = AVPlayer(playerItem: newItem)
                player = newPlayer
            }
            newPlayer.automaticallyWaitsToMinimizeStalling = false

            let newLayer = AVPlayerLayer(player: newPlayer)
            playerLayer?.removeFromSuperlayer()
            playerLayer = newLayer
            renderView.layer.insertSublayer(newLayer, at: 0)
            updateVideoGravity()

            loadState = .prepare
            _prepareToPlay.send(url)

            setupKVO(for: newItem)
            addTimeObserver(player: newPlayer)
            addEndObserver(item: newItem)

            layoutPlayerLayer()
        }

        private func setupKVO(for item: AVPlayerItem) {
            kvoManager.invalidate()
            kvoManager = KVOManager()

            kvoManager.observe(item, keyPath: \.status) { [weak self] _, _ in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.isReadyToPlay = true
                    self.isPreparedToPlay = true
                    self.totalTime = CMTimeGetSeconds(item.duration)
                    self.loadState = .playable

                    if self.seekTime > 0 {
                        Task { [weak self] in
                            guard let self else { return }
                            _ = await self.seek(to: self.seekTime)
                            self.seekTime = 0
                        }
                    }

                    if let url = self.assetURL {
                        self._readyToPlay.send(url)
                    }

                    if self.shouldAutoPlay {
                        self.play()
                    }

                case .failed:
                    self.playbackState = .failed
                    if let error = item.error {
                        self._playFailed.send(error)
                    }

                default:
                    break
                }
            }

            kvoManager.observe(item, keyPath: \.isPlaybackBufferEmpty) { [weak self] _, _ in
                guard let self, item.isPlaybackBufferEmpty else { return }
                self.loadState = .stalled
                self.bufferingSomeSecond()
            }

            kvoManager.observe(item, keyPath: \.isPlaybackLikelyToKeepUp) { [weak self] _, _ in
                guard let self, item.isPlaybackLikelyToKeepUp else { return }
                self.loadState = [.playable, .playthroughOK]
                if self.isPlaying {
                    self.player?.play()
                }
            }

            kvoManager.observe(item, keyPath: \.loadedTimeRanges) { [weak self] _, _ in
                self?.updateBufferTime()
            }

            kvoManager.observe(item, keyPath: \.presentationSize) { [weak self] _, _ in
                guard let self else { return }
                self.presentationSize = item.presentationSize
                self.renderView.presentationSize = item.presentationSize
            }
        }

        private func addTimeObserver(player: AVPlayer) {
            removeTimeObserver()
            let interval = CMTime(seconds: timeRefreshInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self, let item = self.playerItem else { return }
                let current = CMTimeGetSeconds(time)
                let total = CMTimeGetSeconds(item.duration)
                guard current >= 0, total > 0 else { return }
                self.currentTime = current
                self.totalTime = total
                self._playTime.send((current: current, total: total))
            }
        }

        private func removeTimeObserver() {
            if let observer = timeObserver {
                player?.removeTimeObserver(observer)
                timeObserver = nil
            }
        }

        private func addEndObserver(item: AVPlayerItem) {
            removeEndObserver()
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.playbackState = .stopped
                self._didPlayToEnd.send()
            }
        }

        private func removeEndObserver() {
            if let observer = endObserver {
                NotificationCenter.default.removeObserver(observer)
                endObserver = nil
            }
        }

        private func updateBufferTime() {
            guard let item = playerItem,
                  let range = item.loadedTimeRanges.first?.timeRangeValue
            else { return }
            let start = CMTimeGetSeconds(range.start)
            let duration = CMTimeGetSeconds(range.duration)
            let newBufferTime = start + duration
            bufferTime = newBufferTime
            _bufferTime.send(newBufferTime)
        }

        private func bufferingSomeSecond() {
            guard !isBuffering else { return }
            isBuffering = true
            player?.pause()

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self else { return }
                self.isBuffering = false
                guard let item = self.playerItem else { return }
                if item.isPlaybackLikelyToKeepUp {
                    if self.isPlaying {
                        self.player?.play()
                    }
                } else {
                    self.bufferingSomeSecond()
                }
            }
        }

        private func updateVideoGravity() {
            let gravity: AVLayerVideoGravity = switch scalingMode {
            case .none, .aspectFit: .resizeAspect
            case .aspectFill: .resizeAspectFill
            case .fill: .resize
            }
            playerLayer?.videoGravity = gravity
        }

        private func layoutPlayerLayer() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer?.frame = renderView.bounds
            CATransaction.commit()

            // 监听 renderView 布局变化
            renderView.layoutSubviewsCallback = { [weak self] in
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self?.playerLayer?.frame = self?.renderView.bounds ?? .zero
                CATransaction.commit()
            }
        }
    }
#endif
