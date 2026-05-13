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

    private let session = AlloyPlayerFactory.makeDefaultSession()
    private lazy var playerView = AlloyPlayerView(session: session)
    private let fullscreenCoordinator = FullscreenCoordinator()
    private let controlOverlay = DefaultControlOverlay()
    private var cancellables = Set<AnyCancellable>()
    private var playbackTask: Task<Void, Never>?
    private var selectedSampleGroup: VideoSampleGroup = .hls
    private var currentSampleIndex = 0
    private var currentSamples: [VideoItem] {
        selectedSampleGroup.samples
    }

    private var isScreenLocked = false

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupPlayer()
        updateStatusLabel()
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
        view.addSubview(buttonStack)
        view.addSubview(statusLabel)

        // 操作按钮
        let sampleGroupControl = makeSegmentedControl(action: #selector(sampleGroupChanged(_:)))
        let nextSampleButton = makeButton(title: "切换下一个素材", action: #selector(playNextSample))
        let landscapeButton = makeButton(title: "进入横屏全屏", action: #selector(enterLandscapeFullScreen))
        let portraitButton = makeButton(title: "进入竖屏全屏", action: #selector(enterPortraitFullScreen))
        let autoButton = makeButton(title: "自动全屏", action: #selector(enterAutoFullScreen))
        let lockButton = makeButton(title: "切换锁屏", action: #selector(toggleLockScreen))
        let exitButton = makeButton(title: "退出全屏", action: #selector(exitFullScreen))

        for item in [sampleGroupControl, nextSampleButton, landscapeButton, portraitButton, autoButton, lockButton, exitButton] {
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
        playerView.controlOverlay = controlOverlay
        playerView.fullscreenCoordinator = fullscreenCoordinator
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerContainerView.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor),
        ])

        playCurrentVideo()

        fullscreenCoordinator.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusLabel()
            }
            .store(in: &cancellables)
    }

    private func playCurrentVideo() {
        guard currentSamples.indices.contains(currentSampleIndex) else { return }
        let video = currentSamples[currentSampleIndex]
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: video.makeCoverImage(), fullScreenMode: .automatic)
        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak playerView] in
            guard let playerView else { return }
            do {
                _ = try await playerView.prepareDemoPlayback(originalURL: video.url)
            } catch {
                playerView.load(PlaybackSource(url: video.url))
            }
        }
        updateStatusLabel()
    }

    // MARK: - Actions

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

    @objc private func enterLandscapeFullScreen() {
        Task {
            fullscreenCoordinator.configuration.mode = .landscape
            controlOverlay.fullScreenMode = .landscape
            await fullscreenCoordinator.setFullscreen(true, animated: true)
            updateStatusLabel()
        }
    }

    @objc private func enterPortraitFullScreen() {
        Task {
            fullscreenCoordinator.configuration.mode = .portrait
            controlOverlay.fullScreenMode = .portrait
            await fullscreenCoordinator.setFullscreen(true, animated: true)
            updateStatusLabel()
        }
    }

    @objc private func enterAutoFullScreen() {
        Task {
            fullscreenCoordinator.configuration.mode = .automatic
            controlOverlay.fullScreenMode = .automatic
            await fullscreenCoordinator.setFullscreen(true, animated: true)
            updateStatusLabel()
        }
    }

    @objc private func toggleLockScreen() {
        isScreenLocked.toggle()
        updateStatusLabel()
    }

    @objc private func exitFullScreen() {
        Task {
            await fullscreenCoordinator.setFullscreen(false, animated: true)
            updateStatusLabel()
        }
    }

    // MARK: - 辅助

    private func updateStatusLabel() {
        guard currentSamples.indices.contains(currentSampleIndex) else { return }

        statusLabel.text = """
        全屏模式: \(fullscreenModeText(fullscreenCoordinator.configuration.mode))
        是否全屏: \(fullscreenCoordinator.state == .fullscreen ? "是" : "否")
        是否锁屏: \(isScreenLocked ? "是" : "否")
        当前素材: \(currentSamples[currentSampleIndex].title)
        """
    }

    private func fullscreenModeText(_ mode: FullscreenMode) -> String {
        switch mode {
        case .automatic: return "自动"
        case .landscape: return "横屏"
        case .portrait: return "竖屏"
        }
    }

    private func makeSegmentedControl(action: Selector) -> UISegmentedControl {
        let sc = UISegmentedControl(items: VideoSampleGroup.allCases.map(\.title))
        sc.selectedSegmentIndex = selectedSampleGroup.rawValue
        sc.addTarget(self, action: action, for: .valueChanged)
        sc.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return sc
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
