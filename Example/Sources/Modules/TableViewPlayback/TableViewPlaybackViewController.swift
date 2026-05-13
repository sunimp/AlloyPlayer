//
//  TableViewPlaybackViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyPlayer
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

    private let session = AlloyPlayerFactory.makeDefaultSession()
    private lazy var playerView = AlloyPlayerView(session: session)
    private lazy var listPlayback = ListPlaybackCoordinator(playerView: playerView)
    private let controlOverlay = DefaultControlOverlay()
    private var playbackTask: Task<Void, Never>?

    private let videos = VideoResource.allSamples

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
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupPlayer() {
        playerView.controlOverlay = controlOverlay
        listPlayback.configuration.minimumVisiblePercent = 0.5
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
        )
        guard let videoCell = cell as? VideoTableViewCell else {
            assertionFailure("无法复用 VideoTableViewCell")
            return cell
        }
        videoCell.configure(with: videos[indexPath.row])
        return videoCell
    }
}

// MARK: - UITableViewDelegate

extension TableViewPlaybackViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = videos[indexPath.row]
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: video.makeCoverImage(), fullScreenMode: .automatic)
        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak self] in
            guard let self,
                  let cell = tableView.cellForRow(at: indexPath) as? VideoTableViewCell
            else { return }
            do {
                let source = try await DemoPlaybackConfiguration.shared.playbackSource(for: video.url)
                let candidate = ListPlaybackCandidate(id: indexPath.description, frame: cell.frame, source: source)
                _ = listPlayback.update(
                    candidates: [candidate],
                    viewport: tableView.bounds,
                    containerProvider: { _ in cell.videoContainerView }
                )
            } catch {
                let candidate = ListPlaybackCandidate(id: indexPath.description, frame: cell.frame, source: PlaybackSource(url: video.url))
                _ = listPlayback.update(
                    candidates: [candidate],
                    viewport: tableView.bounds,
                    containerProvider: { _ in cell.videoContainerView }
                )
            }
        }
    }
}
