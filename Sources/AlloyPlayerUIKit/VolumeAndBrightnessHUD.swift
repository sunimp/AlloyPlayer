//
//  VolumeAndBrightnessHUD.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import MediaPlayer
    import UIKit

    /// 音量/亮度浮层提示
    @MainActor
    public final class VolumeAndBrightnessHUD: UIView {
        /// HUD 展示类型。
        public enum HUDType: Sendable {
            /// 音量调节。
            case volume

            /// 亮度调节。
            case brightness
        }

        /// 当前 HUD 展示类型。
        public private(set) var hudType: HUDType = .volume

        /// HUD 进度条。
        public private(set) var progressView: UIProgressView = {
            let v = UIProgressView(progressViewStyle: .default)
            v.trackTintColor = UIColor(white: 0.5, alpha: 0.3)
            v.progressTintColor = .white
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        /// HUD 图标视图。
        public private(set) var iconImageView: UIImageView = {
            let v = UIImageView()
            v.contentMode = .scaleAspectFit
            v.tintColor = .white
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        private var volumeView: MPVolumeView?
        private var hideTimer: Timer?

        override public init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor(white: 0, alpha: 0.7)
            layer.cornerRadius = 8
            clipsToBounds = true
            isHidden = true

            addSubview(iconImageView)
            addSubview(progressView)
            NSLayoutConstraint.activate([
                iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 20),
                iconImageView.heightAnchor.constraint(equalToConstant: 20),
                progressView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
                progressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        }

        /// 不支持从 Interface Builder 或 Storyboard 创建。
        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// 更新音量或亮度 HUD。
        public func update(progress: CGFloat, type: HUDType) {
            hudType = type
            progressView.progress = Float(max(0, min(1, progress)))
            let config = UIImage.SymbolConfiguration(pointSize: 16)
            iconImageView.image = switch type {
            case .volume: UIImage(systemName: progress > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill", withConfiguration: config)
            case .brightness: UIImage(systemName: "sun.max.fill", withConfiguration: config)
            }
            show()
        }

        /// 添加系统音量视图以接管音量控制。
        public func addSystemVolumeView() {
            guard volumeView == nil else { return }
            let v = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 100, height: 100))
            v.isHidden = false
            addSubview(v)
            volumeView = v
        }

        /// 移除系统音量视图。
        public func removeSystemVolumeView() {
            volumeView?.removeFromSuperview()
            volumeView = nil
        }

        private func show() {
            isHidden = false
            hideTimer?.invalidate()
            hideTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in self?.isHidden = true }
            }
        }
    }
#endif
