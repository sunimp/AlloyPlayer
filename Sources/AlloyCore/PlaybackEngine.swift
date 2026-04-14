//
//  PlaybackEngine.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import Combine
    import UIKit

    /// 播放引擎协议
    ///
    /// 定义视频播放引擎的标准接口。
    /// 内置实现为 `AVPlayerManager`（AlloyAVPlayer 模块），
    /// 也可自定义实现对接第三方播放器。
    @MainActor
    public protocol PlaybackEngine: AnyObject {
        // MARK: - 渲染

        /// 播放器渲染视图
        var renderView: RenderView { get }

        // MARK: - 状态

        /// 播放状态
        var playbackState: PlaybackState { get }

        /// 加载状态
        var loadState: LoadState { get }

        /// 是否正在播放
        var isPlaying: Bool { get }

        /// 是否已准备好播放
        var isPreparedToPlay: Bool { get }

        // MARK: - 控制属性

        /// 音量 (0.0 ~ 1.0)
        var volume: Float { get set }

        /// 是否静音
        var isMuted: Bool { get set }

        /// 播放速率 (0.5 ~ 2.0)
        var rate: Float { get set }

        /// 视频缩放模式
        var scalingMode: ScalingMode { get set }

        /// 是否自动播放
        var shouldAutoPlay: Bool { get set }

        // MARK: - 时间

        /// 当前播放时间（秒）
        var currentTime: TimeInterval { get }

        /// 总时长（秒）
        var totalTime: TimeInterval { get }

        /// 已缓冲时长（秒）
        var bufferTime: TimeInterval { get }

        /// 跳转目标时间（秒）
        var seekTime: TimeInterval { get set }

        // MARK: - 资源

        /// 视频资源 URL
        var assetURL: URL? { get set }

        /// 视频原始尺寸
        var presentationSize: CGSize { get }

        // MARK: - Combine 事件流

        /// 播放状态变化
        var statePublisher: AnyPublisher<PlaybackState, Never> { get }

        /// 加载状态变化
        var loadStatePublisher: AnyPublisher<LoadState, Never> { get }

        /// 播放时间变化 (current, total)
        var playTimePublisher: AnyPublisher<(current: TimeInterval, total: TimeInterval), Never> { get }

        /// 缓冲时间变化
        var bufferTimePublisher: AnyPublisher<TimeInterval, Never> { get }

        /// 准备播放
        var prepareToPlayPublisher: AnyPublisher<URL, Never> { get }

        /// 准备就绪
        var readyToPlayPublisher: AnyPublisher<URL, Never> { get }

        /// 播放失败
        var playFailedPublisher: AnyPublisher<any Error, Never> { get }

        /// 播放完成
        var didPlayToEndPublisher: AnyPublisher<Void, Never> { get }

        /// 视频尺寸变化
        var presentationSizePublisher: AnyPublisher<CGSize, Never> { get }

        // MARK: - 控制方法

        /// 准备播放
        func prepareToPlay()

        /// 重新加载播放器
        func reloadPlayer()

        /// 开始播放
        func play()

        /// 暂停播放
        func pause()

        /// 重新播放（从头开始）
        func replay()

        /// 停止播放并释放资源
        func stop()

        /// 跳转到指定时间
        /// - Parameter time: 目标时间（秒）
        /// - Returns: 是否跳转成功
        func seek(to time: TimeInterval) async -> Bool

        // MARK: - 截图

        /// 获取当前帧截图（同步）
        func thumbnailImageAtCurrentTime() -> UIImage?

        /// 获取当前帧截图（异步）
        func thumbnailImageAtCurrentTime() async -> UIImage?
    }

    // MARK: - 默认实现

    public extension PlaybackEngine {
        func thumbnailImageAtCurrentTime() -> UIImage? {
            nil
        }

        func thumbnailImageAtCurrentTime() async -> UIImage? {
            nil
        }
    }
#endif
