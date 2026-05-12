//
//  FloatingPlaybackDemoViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/5/12.
//

import AlloyPlayer
import UIKit

// MARK: - FloatingPlaybackDemoViewController

/// 浮动小窗播放展示
final class FloatingPlaybackDemoViewController: UIViewController {
    // MARK: - 子视图

    private let playerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.text = "播放器先挂载在页面容器中。点击“显示小窗”后，FloatingPlaybackCoordinator 会把同一个播放器渲染面迁移到浮动窗口；点击“回到页面容器”会重新挂回当前页面。"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var showFloatingButton: UIButton = makeActionButton(
        title: "显示小窗",
        action: #selector(showFloatingButtonTapped)
    )

    private lazy var hideFloatingButton: UIButton = makeActionButton(
        title: "隐藏小窗",
        action: #selector(hideFloatingButtonTapped)
    )

    private lazy var attachBackButton: UIButton = makeActionButton(
        title: "回到页面容器",
        action: #selector(attachBackButtonTapped)
    )

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 播放器

    private var player: Player?
    private var floatingPlayback: FloatingPlaybackCoordinator?
    private let controlOverlay = DefaultControlOverlay()
    private var playbackTask: Task<Void, Never>?
    private let video = VideoResource.mp4Samples[0]

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupPlayer()
        updateStatus("播放器已挂载在页面容器")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player?.isViewControllerDisappear = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.isViewControllerDisappear = true
    }

    deinit {
        MainActor.assumeIsolated {
            playbackTask?.cancel()
            floatingPlayback?.hide()
            player?.stop()
        }
    }

    // MARK: - 配置

    private func setupUI() {
        let buttonStack = UIStackView(arrangedSubviews: [
            showFloatingButton,
            hideFloatingButton,
            attachBackButton,
        ])
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(playerContainerView)
        view.addSubview(descriptionLabel)
        view.addSubview(buttonStack)
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            playerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 9.0 / 16.0),

            descriptionLabel.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            buttonStack.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    private func setupPlayer() {
        let engine = AVPlayerManager()
        engine.shouldAutoPlay = true

        let player = Player(engine: engine, containerView: playerContainerView)
        player.controlOverlay = controlOverlay
        player.addDeviceOrientationObserver()
        self.player = player

        controlOverlay.show(title: video.title, coverImage: video.makeCoverImage(), fullScreenMode: .automatic)
        playbackTask = Task { @MainActor [weak player] in
            guard let player else { return }
            do {
                _ = try await player.prepareDemoPlayback(originalURL: video.url)
            } catch {
                player.assetURL = video.url
            }
        }

        floatingPlayback = FloatingPlaybackCoordinator(
            player: player,
            parentView: view
        )
    }

    private func makeActionButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func updateStatus(_ text: String) {
        statusLabel.text = "当前状态：\(text)"
    }

    // MARK: - Actions

    @objc private func showFloatingButtonTapped() {
        floatingPlayback?.show()
        updateStatus("播放器已迁移到浮动小窗")
    }

    @objc private func hideFloatingButtonTapped() {
        floatingPlayback?.hide()
        updateStatus("小窗已隐藏，播放器渲染面暂未挂载")
    }

    @objc private func attachBackButtonTapped() {
        floatingPlayback?.hide()
        player?.attach(to: playerContainerView)
        updateStatus("播放器已回到页面容器")
    }
}
