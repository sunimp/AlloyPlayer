//
//  FullScreenModesViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyPlayer
import Combine
import UIKit

// MARK: - FullScreenModesViewController

/// 全屏模式演示
final class FullScreenModesViewController: UIViewController {
    // MARK: - 子视图

    private let playerContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let buttonStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - 播放器

    private var player: Player?
    private let controlOverlay = DefaultControlOverlay()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupPlayer()
        updateStatusLabel()
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
        view.addSubview(buttonStack)
        view.addSubview(statusLabel)

        // 操作按钮
        let landscapeButton = makeButton(title: "进入横屏全屏", action: #selector(enterLandscapeFullScreen))
        let portraitButton = makeButton(title: "进入竖屏全屏", action: #selector(enterPortraitFullScreen))
        let autoButton = makeButton(title: "自动全屏", action: #selector(enterAutoFullScreen))
        let lockButton = makeButton(title: "切换锁屏", action: #selector(toggleLockScreen))
        let exitButton = makeButton(title: "退出全屏", action: #selector(exitFullScreen))

        for item in [landscapeButton, portraitButton, autoButton, lockButton, exitButton] {
            buttonStack.addArrangedSubview(item)
        }

        NSLayoutConstraint.activate([
            playerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 9.0 / 16.0),

            buttonStack.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: 24),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 24),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func setupPlayer() {
        let engine = AVPlayerManager()
        engine.shouldAutoPlay = true

        let player = Player(engine: engine, containerView: playerContainerView)
        player.controlOverlay = controlOverlay
        player.addDeviceOrientationObserver()
        self.player = player

        let video = VideoResource.hlsSamples[0]
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: video.makeCoverImage(), fullScreenMode: .automatic)
        player.assetURL = video.url

        // 监听旋转事件
        player.orientationDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusLabel()
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func enterLandscapeFullScreen() {
        guard let player else { return }
        Task {
            await player.rotate(to: .landscapeRight, animated: true)
            updateStatusLabel()
        }
    }

    @objc private func enterPortraitFullScreen() {
        guard let player else { return }
        Task {
            await player.enterPortraitFullScreen(true, animated: true)
            updateStatusLabel()
        }
    }

    @objc private func enterAutoFullScreen() {
        guard let player else { return }
        Task {
            await player.enterFullScreen(true, animated: true)
            updateStatusLabel()
        }
    }

    @objc private func toggleLockScreen() {
        guard let player else { return }
        player.isScreenLocked.toggle()
        updateStatusLabel()
    }

    @objc private func exitFullScreen() {
        guard let player else { return }
        Task {
            await player.enterFullScreen(false, animated: true)
            updateStatusLabel()
        }
    }

    // MARK: - 辅助

    private func updateStatusLabel() {
        guard let player else { return }
        let orientation = player.orientationManager.currentOrientation
        let orientationText: String
        switch orientation {
        case .portrait: orientationText = "竖屏"
        case .portraitUpsideDown: orientationText = "倒置竖屏"
        case .landscapeLeft: orientationText = "横屏左"
        case .landscapeRight: orientationText = "横屏右"
        default: orientationText = "未知"
        }

        statusLabel.text = """
        当前方向: \(orientationText)
        是否全屏: \(player.isFullScreen ? "是" : "否")
        是否锁屏: \(player.isScreenLocked ? "是" : "否")
        """
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }
}
