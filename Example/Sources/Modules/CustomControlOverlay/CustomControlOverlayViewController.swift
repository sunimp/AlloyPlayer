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

    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.text = """
        此页面展示如何自定义 ControlOverlay：

        • MinimalControlOverlay 实现了 ControlOverlay 协议
        • 仅包含播放/暂停按钮、进度条和时间标签
        • 单击切换控制层可见性
        • 双击播放/暂停
        • 拖拽进度条可跳转
        """
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - 播放器

    private var player: Player?
    private let controlOverlay = MinimalControlOverlay()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupPlayer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.isViewControllerDisappear = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player?.isViewControllerDisappear = false
    }

    deinit {
        MainActor.assumeIsolated {
            player?.stop()
        }
    }

    // MARK: - 配置

    private func setupUI() {
        view.addSubview(playerContainerView)
        view.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            playerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 9.0 / 16.0),

            descriptionLabel.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func setupPlayer() {
        let engine = AVPlayerManager()
        engine.shouldAutoPlay = true

        let player = Player(engine: engine, containerView: playerContainerView)
        player.controlOverlay = controlOverlay
        player.addDeviceOrientationObserver()
        self.player = player

        let video = VideoResource.mp4Samples[0]
        player.assetURL = video.url
    }
}
