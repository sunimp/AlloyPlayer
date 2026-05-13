//
//  AlloyPlayerController.swift
//  AlloyPlayerSwiftUI
//
//  Created by Sun on 2026/5/13.
//

#if canImport(SwiftUI)
    import AlloyAVPlayer
    import AlloyCore
    import Combine
    import Foundation
    import SwiftUI

    /// SwiftUI 外部控制句柄。
    @MainActor
    public final class AlloyPlayerController: ObservableObject {
        /// 控制器绑定的播放会话。
        public let session: PlaybackSession

        /// 当前播放状态快照。
        @Published public private(set) var state: PlaybackStateSnapshot

        private var cancellables = Set<AnyCancellable>()

        /// 使用既有播放会话创建控制器。
        public init(session: PlaybackSession) {
            self.session = session
            state = session.state
            session.statePublisher
                .sink { [weak self] state in
                    self?.state = state
                }
                .store(in: &cancellables)
        }

        /// 创建默认 AVFoundation 播放会话并可选加载播放源。
        public convenience init(
            source: PlaybackSource? = nil,
            sessionConfiguration: PlaybackSessionConfiguration = .init(),
            engineConfiguration: AVPlaybackEngineConfiguration = .init()
        ) {
            let session = PlaybackSession(
                engine: AVPlaybackEngine(configuration: engineConfiguration),
                configuration: sessionConfiguration
            )
            self.init(session: session)

            if let source {
                load(source)
            }
        }

        /// 加载播放源。
        public func load(_ source: PlaybackSource) {
            session.load(source)
        }

        /// 开始或恢复播放。
        public func play() {
            session.play()
        }

        /// 暂停播放。
        public func pause() {
            session.pause()
        }

        /// 停止播放。
        public func stop() {
            session.stop()
        }

        /// 跳转到指定播放时间。
        @discardableResult
        public func seek(to time: TimeInterval) async -> Bool {
            await session.seek(to: time)
        }
    }
#endif
