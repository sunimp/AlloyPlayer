//
//  BasicPlaybackViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyHTTPMediaCacheSupport
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

    private lazy var sampleGroupControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: VideoSampleGroup.allCases.map(\.title))
        sc.selectedSegmentIndex = selectedSampleGroup.rawValue
        sc.addTarget(self, action: #selector(sampleGroupChanged(_:)), for: .valueChanged)
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    // MARK: - 播放器

    private var player: Player?
    private let controlOverlay = DefaultControlOverlay()
    private var cancellables = Set<AnyCancellable>()
    private var playbackTask: Task<Void, Never>?

    // MARK: - 状态数据

    private var playbackState: PlaybackState = .unknown
    private var loadState: LoadState = .unknown
    private var currentTime: TimeInterval = 0
    private var totalTime: TimeInterval = 0
    private var bufferTime: TimeInterval = 0
    private var presentationSize: CGSize = .zero
    private var isHTTPMediaCacheEnabled = false
    private var currentPlaybackURL: URL?
    private var playbackErrorText: String?
    private var currentVideoIndex = 0

    private var selectedSampleGroup: VideoSampleGroup = .hls
    private var videos: [VideoItem] {
        selectedSampleGroup.samples
    }

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
            playbackTask?.cancel()
            player?.stop()
        }
    }

    // MARK: - 配置

    private func setupUI() {
        view.addSubview(playerContainerView)
        view.addSubview(sampleGroupControl)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            playerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 9.0 / 16.0),

            sampleGroupControl.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: 12),
            sampleGroupControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sampleGroupControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: sampleGroupControl.bottomAnchor, constant: 12),
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
        currentVideoIndex = index
        playbackTask?.cancel()

        let video = videos[index]
        currentPlaybackURL = nil
        playbackErrorText = nil
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: video.makeCoverImage(), fullScreenMode: .automatic)
        reloadStatusRow(6)

        guard isHTTPMediaCacheEnabled else {
            currentPlaybackURL = video.url
            player?.assetURL = video.url
            reloadStatusRow(6)
            return
        }

        playbackTask = Task { [weak self, weak player] in
            guard let self, let player else { return }
            do {
                let proxyURL = try await AlloyHTTPMediaCacheSupport.prepare(
                    player: player,
                    originalURL: video.url,
                    configuration: .default
                )
                guard !Task.isCancelled else { return }
                currentPlaybackURL = proxyURL
            } catch {
                guard !Task.isCancelled else { return }
                currentPlaybackURL = video.url
                playbackErrorText = "缓存代理失败，已直连播放：\(error.localizedDescription)"
                player.assetURL = video.url
            }
            reloadStatusRow(6)
        }
    }

    @objc private func sampleGroupChanged(_ sender: UISegmentedControl) {
        guard let group = VideoSampleGroup(rawValue: sender.selectedSegmentIndex) else { return }
        selectedSampleGroup = group
        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        playVideo(at: 0)
    }

    @objc private func httpMediaCacheSwitchChanged(_ sender: UISwitch) {
        isHTTPMediaCacheEnabled = sender.isOn
        tableView.reloadRows(at: [IndexPath(row: 5, section: 0)], with: .none)
        playVideo(at: currentVideoIndex)
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

    private func currentPlaybackURLText() -> String {
        if let playbackErrorText {
            return playbackErrorText
        }
        guard let currentPlaybackURL else {
            return isHTTPMediaCacheEnabled ? "正在生成缓存代理 URL" : "未开始"
        }
        return currentPlaybackURL.absoluteString
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
        section == 0 ? 7 : videos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatusCell", for: indexPath)
            cell.accessoryView = nil
            cell.selectionStyle = .none
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
            case 5:
                config.text = "HTTPMediaCache"
                config.secondaryText = isHTTPMediaCacheEnabled ? "开启，播放前转换为本地代理 URL" : "关闭，直接播放原始 URL"
                let toggle = UISwitch()
                toggle.isOn = isHTTPMediaCacheEnabled
                toggle.addTarget(self, action: #selector(httpMediaCacheSwitchChanged(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            case 6:
                config.text = "当前播放 URL"
                config.secondaryText = currentPlaybackURLText()
            default:
                break
            }
            config.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = config
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath)
            cell.accessoryView = nil
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
