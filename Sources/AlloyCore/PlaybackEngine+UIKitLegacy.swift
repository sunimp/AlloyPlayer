//
//  PlaybackEngine+UIKitLegacy.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import Combine
    import Foundation
    import UIKit

    public extension PlaybackEngine {
        var renderView: RenderView {
            if let renderView = renderSurface as? RenderView {
                return renderView
            }

            if let child = Mirror(reflecting: self).children.first(where: { $0.label == "renderView" }),
               let renderView = child.value as? RenderView
            {
                return renderView
            }

            preconditionFailure("PlaybackEngine 未提供 RenderView")
        }

        var playbackState: PlaybackState {
            snapshot.playbackState
        }

        var loadState: LoadState {
            snapshot.loadState
        }

        var isPlaying: Bool {
            snapshot.playbackState == .playing
        }

        var isPreparedToPlay: Bool {
            snapshot.playbackState == .ready || snapshot.loadState.contains(.playable)
        }

        var volume: Float {
            get { snapshot.volume }
            set { setVolume(newValue) }
        }

        var isMuted: Bool {
            get { snapshot.isMuted }
            set { setMuted(newValue) }
        }

        var rate: Float {
            get { snapshot.rate }
            set { setRate(newValue) }
        }

        var scalingMode: ScalingMode {
            get { .aspectFit }
            set { setScalingMode(newValue) }
        }

        var shouldAutoPlay: Bool {
            get { false }
            set { _ = newValue }
        }

        var currentTime: TimeInterval {
            snapshot.currentTime
        }

        var totalTime: TimeInterval {
            snapshot.duration
        }

        var bufferTime: TimeInterval {
            snapshot.bufferedTime
        }

        var seekTime: TimeInterval {
            get { snapshot.currentTime }
            set { _ = newValue }
        }

        var assetURL: URL? {
            get { snapshot.source?.url }
            set {
                guard let newValue else {
                    stop()
                    return
                }
                load(PlaybackSource(url: newValue))
            }
        }

        var statePublisher: AnyPublisher<PlaybackState, Never> {
            snapshotPublisher.map(\.playbackState).eraseToAnyPublisher()
        }

        var loadStatePublisher: AnyPublisher<LoadState, Never> {
            snapshotPublisher.map(\.loadState).eraseToAnyPublisher()
        }

        var playTimePublisher: AnyPublisher<(current: TimeInterval, total: TimeInterval), Never> {
            snapshotPublisher
                .map { (current: $0.currentTime, total: $0.duration) }
                .eraseToAnyPublisher()
        }

        var bufferTimePublisher: AnyPublisher<TimeInterval, Never> {
            snapshotPublisher.map(\.bufferedTime).eraseToAnyPublisher()
        }

        var prepareToPlayPublisher: AnyPublisher<URL, Never> {
            eventPublisher.compactMap {
                if case let .didLoad(source) = $0 { return source.url }
                return nil
            }
            .eraseToAnyPublisher()
        }

        var readyToPlayPublisher: AnyPublisher<URL, Never> {
            eventPublisher.compactMap {
                if case let .readyToPlay(source) = $0 { return source.url }
                return nil
            }
            .eraseToAnyPublisher()
        }

        var playFailedPublisher: AnyPublisher<any Error, Never> {
            eventPublisher.compactMap {
                if case let .failed(error) = $0 { return error }
                return nil
            }
            .eraseToAnyPublisher()
        }

        var didPlayToEndPublisher: AnyPublisher<Void, Never> {
            eventPublisher.compactMap {
                if case .didPlayToEnd = $0 { return () }
                return nil
            }
            .eraseToAnyPublisher()
        }

        var presentationSizePublisher: AnyPublisher<CGSize, Never> {
            eventPublisher.compactMap {
                if case let .presentationSizeChanged(size) = $0 { return size }
                return nil
            }
            .eraseToAnyPublisher()
        }

        func prepareToPlay() {
            guard let source = snapshot.source else { return }
            load(source)
        }

        func reloadPlayer() {
            guard let source = snapshot.source else { return }
            load(source)
        }

        func replay() {
            Task {
                _ = await seek(to: 0)
                play()
            }
        }

        func thumbnailImageAtCurrentTime() -> UIImage? {
            nil
        }

        func thumbnailImageAtCurrentTime() async -> UIImage? {
            nil
        }
    }
#endif
