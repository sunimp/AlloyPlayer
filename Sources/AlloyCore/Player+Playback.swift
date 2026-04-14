//
//  Player+Playback.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import Foundation

    // MARK: - 播放控制扩展

    public extension Player {
        /// 停止播放
        func stop() {
            engine.stop()
            systemEventObserver?.stopObserving()
            systemEventObserver = nil

            if exitFullScreenWhenStop, isFullScreen {
                Task {
                    await orientationManager.enterFullScreen(false, animated: true)
                }
            }
        }

        /// 替换播放引擎
        func replaceEngine(_ newEngine: PlaybackEngine) {
            engine.stop()
            engine = newEngine
        }

        /// 播放下一个
        func playNext() {
            guard let urls = assetURLs, currentPlayIndex < urls.count - 1 else { return }
            currentPlayIndex += 1
            assetURL = urls[currentPlayIndex]
        }

        /// 播放上一个
        func playPrevious() {
            guard let urls = assetURLs, currentPlayIndex > 0 else { return }
            currentPlayIndex -= 1
            assetURL = urls[currentPlayIndex]
        }

        /// 播放指定索引
        func play(at index: Int) {
            guard let urls = assetURLs, index >= 0, index < urls.count else { return }
            currentPlayIndex = index
            assetURL = urls[index]
        }

        /// 跳转到指定时间
        @discardableResult
        func seek(to time: TimeInterval) async -> Bool {
            await engine.seek(to: time)
        }
    }
#endif
