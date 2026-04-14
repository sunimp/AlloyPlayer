//
//  TableViewPlaybackViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyPlayer
import Combine
import UIKit

// MARK: - TableViewPlaybackViewController

/// TableView 列表播放演示
final class TableViewPlaybackViewController: UIViewController {
    // MARK: - 子视图

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.dataSource = self
        tv.delegate = self
        tv.register(VideoTableViewCell.self, forCellReuseIdentifier: VideoTableViewCell.reuseIdentifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 280
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - 播放器

    private var player: Player?
    private let controlOverlay = DefaultControlOverlay()
    private var cancellables = Set<AnyCancellable>()

    private let videos = VideoResource.allSamples

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
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupPlayer() {
        let engine = AVPlayerManager()
        engine.shouldAutoPlay = true

        let player = Player(scrollView: tableView, engine: engine, containerViewTag: 100)
        player.controlOverlay = controlOverlay
        player.shouldAutoPlay = true
        player.disappearPercent = 0.8
        player.addDeviceOrientationObserver()

        // 配置列表 URL 数据源
        player.sectionAssetURLs = [videos.map(\.url)]

        self.player = player

        // 监听播放器消失事件，展示小窗
        player.playerDidDisappearPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.player?.addPlayerViewToFloatingView()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource

extension TableViewPlaybackViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        videos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: VideoTableViewCell.reuseIdentifier,
            for: indexPath
        ) as! VideoTableViewCell
        cell.configure(with: videos[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TableViewPlaybackViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = videos[indexPath.row]
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: nil, fullScreenMode: .automatic)
        player?.play(at: indexPath, assetURL: video.url)
    }
}
