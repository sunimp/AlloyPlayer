//
//  MinimalControlOverlay.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyPlayer
import Combine
import UIKit

// MARK: - MinimalControlOverlay

/// 极简自定义控制层
///
/// 演示如何实现 ControlOverlay 协议。
/// 仅包含：半透明黑底、居中播放/暂停按钮、底部进度条。
final class MinimalControlOverlay: UIView, ControlOverlay {
    // MARK: - ControlOverlay

    weak var player: Player?

    // MARK: - 子视图

    /// 半透明遮罩
    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.35)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 播放/暂停按钮
    private let playButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular)
        btn.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 底部进度条
    private let progressSlider: ProgressSlider = {
        let s = ProgressSlider()
        s.trackHeight = 3
        s.isThumbHidden = false
        s.thumbSize = CGSize(width: 14, height: 14)
        s.maximumTrackTintColor = UIColor(white: 1, alpha: 0.3)
        s.minimumTrackTintColor = .white
        s.bufferTrackTintColor = UIColor(white: 1, alpha: 0.5)
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    /// 时间标签
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        l.textColor = .white
        l.text = "00:00 / 00:00"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - 状态

    private var isShowing = true
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(overlayView)
        addSubview(playButton)
        addSubview(progressSlider)
        addSubview(timeLabel)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),

            playButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 70),
            playButton.heightAnchor.constraint(equalToConstant: 70),

            progressSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            progressSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            progressSlider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            progressSlider.heightAnchor.constraint(equalToConstant: 30),

            timeLabel.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: progressSlider.topAnchor, constant: -2),
        ])
    }

    private func setupActions() {
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)

        progressSlider.touchEndedPublisher
            .sink { [weak self] value in
                guard let self, let player = self.player else { return }
                let seekTime = player.totalTime * Double(value)
                Task {
                    _ = await player.seek(to: seekTime)
                    player.engine.play()
                }
            }
            .store(in: &cancellables)

        progressSlider.tappedPublisher
            .sink { [weak self] value in
                guard let self, let player = self.player else { return }
                let seekTime = player.totalTime * Double(value)
                Task {
                    _ = await player.seek(to: seekTime)
                    player.engine.play()
                }
            }
            .store(in: &cancellables)
    }

    @objc private func playButtonTapped() {
        guard let player else { return }
        if player.engine.isPlaying {
            player.engine.pause()
        } else {
            player.engine.play()
        }
    }

    // MARK: - 显示/隐藏

    private func toggleVisibility() {
        isShowing.toggle()
        UIView.animate(withDuration: 0.25) {
            self.overlayView.alpha = self.isShowing ? 1 : 0
            self.playButton.alpha = self.isShowing ? 1 : 0
            self.progressSlider.alpha = self.isShowing ? 1 : 0
            self.timeLabel.alpha = self.isShowing ? 1 : 0
        }
    }

    // MARK: - ControlOverlay 回调

    func gestureSingleTapped(_: GestureManager) {
        toggleVisibility()
    }

    func gestureDoubleTapped(_: GestureManager) {
        playButtonTapped()
    }

    func player(_: Player, didUpdateTime currentTime: TimeInterval, totalTime: TimeInterval) {
        let current = TimeFormatter.string(from: Int(currentTime))
        let total = TimeFormatter.string(from: Int(totalTime))
        timeLabel.text = "\(current) / \(total)"

        if !progressSlider.isDragging, totalTime > 0 {
            progressSlider.value = Float(currentTime / totalTime)
        }
    }

    func player(_: Player, didUpdateBufferTime bufferTime: TimeInterval) {
        guard let player, player.totalTime > 0 else { return }
        progressSlider.bufferValue = Float(bufferTime / player.totalTime)
    }

    func player(_: Player, didChangePlaybackState state: PlaybackState) {
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular)
        let imageName = state == .playing ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
    }
}
