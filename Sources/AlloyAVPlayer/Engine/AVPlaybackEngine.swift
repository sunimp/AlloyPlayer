//
//  AVPlaybackEngine.swift
//  AlloyAVPlayer
//
//  Created by Sun on 2026/5/13.
//

import AlloyCore
import AVFoundation
import Combine
import CoreGraphics
import Foundation

/// AVFoundation 播放引擎。
@MainActor
public final class AVPlaybackEngine: PlaybackEngine {
    public private(set) var snapshot: PlaybackEngineSnapshot
    public private(set) var renderSurface: PlaybackRenderSurface?

    public var snapshotPublisher: AnyPublisher<PlaybackEngineSnapshot, Never> {
        snapshotSubject.eraseToAnyPublisher()
    }

    public var eventPublisher: AnyPublisher<PlaybackEngineEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private let configuration: AVPlaybackEngineConfiguration
    private let snapshotSubject: CurrentValueSubject<PlaybackEngineSnapshot, Never>
    private let eventSubject = PassthroughSubject<PlaybackEngineEvent, Never>()

    private var stateMachine = AVPlaybackStateMachine()
    private var asset: AVURLAsset?
    private var playerItem: AVPlayerItem?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?
    private var bufferEmptyObservation: NSKeyValueObservation?
    private var likelyToKeepUpObservation: NSKeyValueObservation?
    private var loadedTimeRangesObservation: NSKeyValueObservation?
    private var presentationSizeObservation: NSKeyValueObservation?
    private var scalingMode: ScalingMode = .aspectFit

    public init(configuration: AVPlaybackEngineConfiguration = .init()) {
        self.configuration = configuration
        snapshot = PlaybackEngineSnapshot()
        snapshotSubject = CurrentValueSubject(snapshot)
    }

    deinit {
        MainActor.assumeIsolated {
            stop()
        }
    }

    public func load(_ source: PlaybackSource) {
        clearPlayer(sendStopped: false)
        _ = stateMachine.apply(.load(source))

        let options: [String: Any]? = source.headers.isEmpty
            ? nil
            : ["AVURLAssetHTTPHeaderFieldsKey": source.headers]
        let newAsset = AVURLAsset(url: source.url, options: options)
        let newItem = AVPlayerItem(asset: newAsset)
        let newPlayer = AVPlayer(playerItem: newItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = configuration.automaticallyWaitsToMinimizeStalling
        let newLayer = AVPlayerLayer(player: newPlayer)
        let surface = AVPlayerRenderSurface(playerLayer: newLayer)

        asset = newAsset
        playerItem = newItem
        player = newPlayer
        playerLayer = newLayer
        renderSurface = surface

        updateSnapshot {
            $0.source = source
            $0.playbackState = .loading
            $0.loadState = .preparing
            $0.currentTime = 0
            $0.duration = 0
            $0.bufferedTime = 0
            $0.presentationSize = .zero
            $0.error = nil
        }
        eventSubject.send(.didLoad(source))

        updateVideoGravity()
        observe(item: newItem)
        addTimeObserver(player: newPlayer)
        addEndObserver(item: newItem)
    }

    public func play() {
        switch stateMachine.state {
        case .ready, .paused:
            break
        case .ended:
            player?.seek(to: .zero)
        default:
            return
        }

        player?.play()
        player?.rate = snapshot.rate
        transition(.play)
    }

    public func pause() {
        player?.pause()
        transition(.pause)
    }

    public func stop() {
        clearPlayer(sendStopped: true)
    }

    public func seek(to time: TimeInterval) async -> Bool {
        guard let player, let playerItem else {
            eventSubject.send(.seekCompleted(time: time, finished: false))
            return false
        }

        transition(.seek(time))
        let timescale = playerItem.asset.duration.timescale
        let targetTime = CMTime(seconds: time, preferredTimescale: timescale)
        let finished = await withCheckedContinuation { continuation in
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
                continuation.resume(returning: finished)
            }
        }
        transition(.seekFinished(finished))
        eventSubject.send(.seekCompleted(time: time, finished: finished))
        return finished
    }

    public func setRate(_ rate: Float) {
        player?.rate = rate
        updateSnapshot { $0.rate = rate }
    }

    public func setMuted(_ isMuted: Bool) {
        player?.isMuted = isMuted
        updateSnapshot { $0.isMuted = isMuted }
    }

    public func setVolume(_ volume: Float) {
        player?.volume = volume
        updateSnapshot { $0.volume = volume }
    }

    public func setScalingMode(_ scalingMode: ScalingMode) {
        self.scalingMode = scalingMode
        updateVideoGravity()
    }

    private func observe(item: AVPlayerItem) {
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                self?.handleStatusChange(item)
            }
        }
        bufferEmptyObservation = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            guard item.isPlaybackBufferEmpty else { return }
            Task { @MainActor [weak self] in
                self?.transition(.bufferEmpty)
            }
        }
        likelyToKeepUpObservation = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            guard item.isPlaybackLikelyToKeepUp else { return }
            Task { @MainActor [weak self] in
                self?.transition(.likelyToKeepUp)
            }
        }
        loadedTimeRangesObservation = item.observe(\.loadedTimeRanges, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.updateBufferTime()
            }
        }
        presentationSizeObservation = item.observe(\.presentationSize, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                self?.updatePresentationSize(item.presentationSize)
            }
        }
    }

    private func handleStatusChange(_ item: AVPlayerItem) {
        switch item.status {
        case .readyToPlay:
            transition(.itemReady)
            updateSnapshot {
                $0.duration = CMTimeGetSeconds(item.duration)
                $0.loadState = .playable
            }
            if let source = snapshot.source {
                eventSubject.send(.readyToPlay(source))
            }
        case .failed:
            let error = PlaybackError(code: .engineFailed, message: item.error?.localizedDescription ?? "AVPlayerItem failed")
            transition(.itemFailed(error))
            eventSubject.send(.failed(error))
        default:
            break
        }
    }

    private func addTimeObserver(player: AVPlayer) {
        removeTimeObserver()
        let interval = CMTime(seconds: configuration.timeRefreshInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self, let item = self.playerItem else { return }
                let current = CMTimeGetSeconds(time)
                let duration = CMTimeGetSeconds(item.duration)
                guard current >= 0, duration > 0 else { return }
                self.updateSnapshot {
                    $0.currentTime = current
                    $0.duration = duration
                }
            }
        }
    }

    private func addEndObserver(item: AVPlayerItem) {
        removeEndObserver()
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.transition(.playToEnd)
                self?.eventSubject.send(.didPlayToEnd)
            }
        }
    }

    private func updateBufferTime() {
        guard let range = playerItem?.loadedTimeRanges.first?.timeRangeValue else { return }
        let bufferedTime = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration)
        updateSnapshot { $0.bufferedTime = bufferedTime }
    }

    private func updatePresentationSize(_ size: CGSize) {
        (renderSurface as? AVPlayerRenderSurface)?.presentationSize = size
        updateSnapshot { $0.presentationSize = size }
        eventSubject.send(.presentationSizeChanged(size))
    }

    private func transition(_ input: AVPlaybackStateMachine.Input) {
        let state = stateMachine.apply(input)
        updateSnapshot { snapshot in
            snapshot.playbackState = playbackState(for: state)
            if case let .failed(_, error) = state {
                snapshot.error = error
            }
        }
    }

    private func playbackState(for state: AVPlaybackStateMachine.State) -> PlaybackState {
        switch state {
        case .idle:
            .idle
        case .loading:
            .loading
        case .ready:
            .ready
        case .playing:
            .playing
        case .paused:
            .paused
        case .seeking:
            .seeking
        case .buffering:
            .buffering
        case .ended:
            .ended
        case .failed:
            .failed
        case .stopped:
            .stopped
        }
    }

    private func updateVideoGravity() {
        let gravity: AVLayerVideoGravity = switch scalingMode {
        case .aspectFit:
            .resizeAspect
        case .aspectFill:
            .resizeAspectFill
        case .fill:
            .resize
        }
        playerLayer?.videoGravity = gravity
    }

    private func updateSnapshot(_ update: (inout PlaybackEngineSnapshot) -> Void) {
        update(&snapshot)
        snapshotSubject.send(snapshot)
    }

    private func clearPlayer(sendStopped: Bool) {
        removeTimeObserver()
        removeEndObserver()
        statusObservation = nil
        bufferEmptyObservation = nil
        likelyToKeepUpObservation = nil
        loadedTimeRangesObservation = nil
        presentationSizeObservation = nil

        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerLayer?.removeFromSuperlayer()

        asset = nil
        playerItem = nil
        player = nil
        playerLayer = nil
        renderSurface = nil

        if sendStopped {
            _ = stateMachine.apply(.stop)
            updateSnapshot {
                $0.playbackState = .stopped
                $0.loadState = []
                $0.currentTime = 0
                $0.duration = 0
                $0.bufferedTime = 0
                $0.presentationSize = .zero
            }
        }
    }

    private func removeTimeObserver() {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }

    private func removeEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }
}
