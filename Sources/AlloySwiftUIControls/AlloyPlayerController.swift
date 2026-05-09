//
//  AlloyPlayerController.swift
//  AlloySwiftUIControls
//
//  Created by Sun on 2026/5/9.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyCore
    import Combine
    import Foundation

    /// SwiftUI 外部控制句柄
    @MainActor
    public final class AlloyPlayerController: ObservableObject {
        public let state = SwiftUIControlOverlayState()

        public private(set) weak var player: Player?

        public init() {}

        public func play() {
            player?.engine.play()
        }

        public func pause() {
            player?.engine.pause()
        }

        public func playOrPause() {
            state.playOrPause()
        }

        public func replay() {
            player?.engine.replay()
        }

        @discardableResult
        public func seek(to time: TimeInterval) async -> Bool {
            await state.seek(to: time)
        }

        @discardableResult
        public func seek(toProgress progress: Float) async -> Bool {
            await state.seek(toProgress: progress)
        }

        public func enterFullScreen(_ fullScreen: Bool, animated: Bool = true) async {
            await state.enterFullScreen(fullScreen, animated: animated)
        }

        public func stop() {
            player?.stop()
        }

        func attach(player: Player?) {
            self.player = player
            state.attach(player: player)
        }

        func detach(player: Player?) {
            guard self.player === player else { return }
            self.player = nil
            state.attach(player: nil)
        }
    }
#endif
