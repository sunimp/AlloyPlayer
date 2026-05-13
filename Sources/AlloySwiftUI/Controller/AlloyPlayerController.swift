//
//  AlloyPlayerController.swift
//  AlloySwiftUI
//
//  Created by Sun on 2026/5/13.
//

#if canImport(SwiftUI)
    import AlloyCore
    import Combine
    import Foundation
    import SwiftUI

    /// SwiftUI 外部控制句柄。
    @MainActor
    public final class AlloyPlayerController: ObservableObject {
        public let session: PlaybackSession
        @Published public private(set) var state: PlaybackStateSnapshot

        private var cancellables = Set<AnyCancellable>()

        public init(session: PlaybackSession) {
            self.session = session
            state = session.state
            session.statePublisher
                .sink { [weak self] state in
                    self?.state = state
                }
                .store(in: &cancellables)
        }

        public func load(_ source: PlaybackSource) {
            session.load(source)
        }

        public func play() {
            session.play()
        }

        public func pause() {
            session.pause()
        }

        public func stop() {
            session.stop()
        }

        @discardableResult
        public func seek(to time: TimeInterval) async -> Bool {
            await session.seek(to: time)
        }
    }
#endif
