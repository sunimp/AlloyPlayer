//
//  BasicPlaybackViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyPlayer
import Combine
import UIKit

// MARK: - BasicPlaybackViewController

/// 基础播放功能展示
final class BasicPlaybackViewController: UIViewController {
    // MARK: - 子视图

    /// 播放器容器
    private let playerContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 状态与播放列表
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.dataSource = self
        tv.delegate = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "StatusCell")
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "VideoCell")
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - 播放器

    private var player: Player?
    private let controlOverlay = DefaultControlOverlay()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 状态数据

    private var playbackState: PlaybackState = .unknown
    private var loadState: LoadState = .unknown
    private var currentTime: TimeInterval = 0
    private var totalTime: TimeInterval = 0
    private var bufferTime: TimeInterval = 0
    private var presentationSize: CGSize = .zero

    private let videos = VideoResource.allSamples

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupPlayer()
        playVideo(at: 0)
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
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            playerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 9.0 / 16.0),

            tableView.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupPlayer() {
        let engine = AVPlayerManager()
        engine.shouldAutoPlay = true

        let player = Player(engine: engine, containerView: playerContainerView)
        player.controlOverlay = controlOverlay
        player.addDeviceOrientationObserver()
        self.player = player

        subscribePlayerEvents()
    }

    private func subscribePlayerEvents() {
        guard let player else { return }

        player.playbackStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.playbackState = state
                self?.tableView.reloadSections(IndexSet(integer: 0), with: .none)
            }
            .store(in: &cancellables)

        player.loadStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.loadState = state
                self?.tableView.reloadSections(IndexSet(integer: 0), with: .none)
            }
            .store(in: &cancellables)

        player.playTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.currentTime = time.current
                self?.totalTime = time.total
                self?.reloadStatusRow(2)
            }
            .store(in: &cancellables)

        player.bufferTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buffer in
                self?.bufferTime = buffer
                self?.reloadStatusRow(3)
            }
            .store(in: &cancellables)

        player.presentationSizePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] size in
                self?.presentationSize = size
                self?.reloadStatusRow(4)
            }
            .store(in: &cancellables)
    }

    private func reloadStatusRow(_ row: Int) {
        let indexPath = IndexPath(row: row, section: 0)
        if tableView.cellForRow(at: indexPath) != nil {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    private func playVideo(at index: Int) {
        let video = videos[index]
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: video.makeCoverImage(), fullScreenMode: .automatic)
        player?.assetURL = video.url
    }

    // MARK: - 辅助

    private func playbackStateText() -> String {
        switch playbackState {
        case .unknown: return "未知"
        case .playing: return "播放中"
        case .paused: return "已暂停"
        case .failed: return "失败"
        case .stopped: return "已停止"
        }
    }

    private func loadStateText() -> String {
        var parts = [String]()
        if loadState.contains(.prepare) { parts.append("准备中") }
        if loadState.contains(.playable) { parts.append("可播放") }
        if loadState.contains(.playthroughOK) { parts.append("缓冲充足") }
        if loadState.contains(.stalled) { parts.append("卡顿") }
        return parts.isEmpty ? "未知" : parts.joined(separator: " | ")
    }
}

// MARK: - UITableViewDataSource

extension BasicPlaybackViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        2
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "实时状态" : "播放列表"
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 5 : videos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatusCell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            switch indexPath.row {
            case 0:
                config.text = "播放状态"
                config.secondaryText = playbackStateText()
            case 1:
                config.text = "加载状态"
                config.secondaryText = loadStateText()
            case 2:
                config.text = "播放进度"
                let current = TimeFormatter.string(from: Int(currentTime))
                let total = TimeFormatter.string(from: Int(totalTime))
                config.secondaryText = "\(current) / \(total)"
            case 3:
                config.text = "缓冲时间"
                config.secondaryText = TimeFormatter.string(from: Int(bufferTime))
            case 4:
                config.text = "视频尺寸"
                config.secondaryText = "\(Int(presentationSize.width)) × \(Int(presentationSize.height))"
            default:
                break
            }
            config.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath)
            let video = videos[indexPath.row]
            var config = cell.defaultContentConfiguration()
            config.text = video.title
            config.secondaryText = video.description
            config.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = config
            cell.accessoryType = .none
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension BasicPlaybackViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1 else { return }
        playVideo(at: indexPath.row)
    }
}
