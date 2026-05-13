//
//  CustomControlOverlayViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyPlayer
import UIKit

// MARK: - CustomControlOverlayViewController

/// 自定义控制层演示
final class CustomControlOverlayViewController: UIViewController {
    // MARK: - 子视图

    private let playerContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var sampleGroupControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: VideoSampleGroup.allCases.map(\.title))
        sc.selectedSegmentIndex = selectedSampleGroup.rawValue
        sc.addTarget(self, action: #selector(sampleGroupChanged(_:)), for: .valueChanged)
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private lazy var nextSampleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("切换下一个素材", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.addTarget(self, action: #selector(playNextSample), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.text = """
        此页面展示如何自定义 UIKitControlOverlay：

        • MinimalControlOverlay 实现了 UIKitControlOverlay 协议
        • 仅包含播放/暂停按钮、进度条和时间标签
        • 单击切换控制层可见性
        • 双击播放/暂停
        • 进度条展示播放与缓冲进度
        • 拖拽或点击进度条可跳转
        • 卡顿时展示缓冲动画
        """
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - 播放器

    private let session = AlloyPlayerFactory.makeDefaultSession()
    private lazy var playerView = AlloyPlayerView(session: session)
    private let controlOverlay = MinimalControlOverlay()
    private var playbackTask: Task<Void, Never>?
    private var selectedSampleGroup: VideoSampleGroup = .hls
    private var currentSampleIndex = 0
    private var currentSamples: [VideoItem] {
        selectedSampleGroup.samples
    }

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupPlayer()
    }

    deinit {
        MainActor.assumeIsolated {
            playbackTask?.cancel()
            playerView.stop()
        }
    }

    // MARK: - 配置

    private func setupUI() {
        view.addSubview(playerContainerView)
        view.addSubview(sampleGroupControl)
        view.addSubview(nextSampleButton)
        view.addSubview(descriptionLabel)

        let playerAspectRatioConstraint = playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 9.0 / 16.0)
        playerAspectRatioConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            playerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerAspectRatioConstraint,

            sampleGroupControl.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: 16),
            sampleGroupControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sampleGroupControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            nextSampleButton.topAnchor.constraint(equalTo: sampleGroupControl.bottomAnchor, constant: 12),
            nextSampleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: nextSampleButton.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func setupPlayer() {
        playerView.controlOverlay = controlOverlay
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerContainerView.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor),
        ])

        playCurrentVideo()
    }

    private func playCurrentVideo() {
        guard currentSamples.indices.contains(currentSampleIndex) else { return }
        let video = currentSamples[currentSampleIndex]
        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak playerView] in
            guard let playerView else { return }
            do {
                _ = try await playerView.prepareDemoPlayback(originalURL: video.url)
            } catch {
                playerView.load(PlaybackSource(url: video.url))
            }
        }
    }

    @objc private func sampleGroupChanged(_ sender: UISegmentedControl) {
        guard let group = VideoSampleGroup(rawValue: sender.selectedSegmentIndex) else { return }
        selectedSampleGroup = group
        currentSampleIndex = 0
        playCurrentVideo()
    }

    @objc private func playNextSample() {
        guard !currentSamples.isEmpty else { return }
        currentSampleIndex = (currentSampleIndex + 1) % currentSamples.count
        playCurrentVideo()
    }
}
