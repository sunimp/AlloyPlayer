//
//  SystemEventObserver.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import AVFoundation
    import Combine
    import UIKit

    /// 系统事件观察者
    ///
    /// 监听应用前后台切换、音频路由变化、音量变化、音频中断等系统事件。
    @MainActor
    public final class SystemEventObserver {
        // MARK: - 状态

        /// 当前前后台状态
        public private(set) var backgroundState: BackgroundState = .foreground

        // MARK: - 音频路由变化原因

        /// 音频路由变化原因
        public enum AudioRouteChangeReason: Sendable {
            /// 新设备可用（如耳机插入）
            case newDeviceAvailable
            /// 旧设备不可用（如耳机拔出）
            case oldDeviceUnavailable
            /// 音频类别变化
            case categoryChanged
        }

        // MARK: - Combine Subjects

        private let _willResignActive = PassthroughSubject<Void, Never>()
        private let _didBecomeActive = PassthroughSubject<Void, Never>()
        private let _audioRouteChange = PassthroughSubject<AudioRouteChangeReason, Never>()
        private let _volumeChanged = PassthroughSubject<Float, Never>()
        private let _audioInterruption = PassthroughSubject<AVAudioSession.InterruptionType, Never>()

        // MARK: - Combine 事件流

        /// 应用即将进入非活跃状态
        public var willResignActivePublisher: AnyPublisher<Void, Never> {
            _willResignActive.eraseToAnyPublisher()
        }

        /// 应用已进入活跃状态
        public var didBecomeActivePublisher: AnyPublisher<Void, Never> {
            _didBecomeActive.eraseToAnyPublisher()
        }

        /// 音频路由变化
        public var audioRouteChangePublisher: AnyPublisher<AudioRouteChangeReason, Never> {
            _audioRouteChange.eraseToAnyPublisher()
        }

        /// 系统音量变化
        public var volumeChangedPublisher: AnyPublisher<Float, Never> {
            _volumeChanged.eraseToAnyPublisher()
        }

        /// 音频中断
        public var audioInterruptionPublisher: AnyPublisher<AVAudioSession.InterruptionType, Never> {
            _audioInterruption.eraseToAnyPublisher()
        }

        // MARK: - 内部状态

        private var isObserving = false

        // MARK: - 初始化

        public init() {}

        // MARK: - 方法

        /// 开始监听系统事件
        public func startObserving() {
            guard !isObserving else { return }
            isObserving = true

            let nc = NotificationCenter.default

            nc.addObserver(
                self,
                selector: #selector(handleWillResignActive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
            nc.addObserver(
                self,
                selector: #selector(handleDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            nc.addObserver(
                self,
                selector: #selector(handleRouteChange(_:)),
                name: AVAudioSession.routeChangeNotification,
                object: nil
            )
            nc.addObserver(
                self,
                selector: #selector(handleInterruption(_:)),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
            nc.addObserver(
                self,
                selector: #selector(handleVolumeChange(_:)),
                name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
                object: nil
            )
        }

        /// 停止监听系统事件
        public func stopObserving() {
            guard isObserving else { return }
            isObserving = false
            NotificationCenter.default.removeObserver(self)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        // MARK: - 通知处理

        @objc private func handleWillResignActive() {
            backgroundState = .background
            _willResignActive.send()
        }

        @objc private func handleDidBecomeActive() {
            backgroundState = .foreground
            _didBecomeActive.send()
        }

        @objc private func handleRouteChange(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
            else { return }

            switch reason {
            case .newDeviceAvailable:
                _audioRouteChange.send(.newDeviceAvailable)
            case .oldDeviceUnavailable:
                _audioRouteChange.send(.oldDeviceUnavailable)
            case .categoryChange:
                _audioRouteChange.send(.categoryChanged)
            default:
                break
            }
        }

        @objc private func handleVolumeChange(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let volume = userInfo["AVSystemController_AudioVolumeNotificationParameter"] as? Float
            else { return }
            _volumeChanged.send(volume)
        }

        @objc private func handleInterruption(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue)
            else { return }
            _audioInterruption.send(type)
        }
    }
#endif
