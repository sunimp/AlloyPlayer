//
//  PlaybackSettingsViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyPlayer
import UIKit

// MARK: - PlaybackSettingsViewController

/// 播放配置游乐场
final class PlaybackSettingsViewController: UIViewController {
    // MARK: - 子视图

    private let playerContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.dataSource = self
        tv.delegate = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - 播放器

    private var player: Player?
    private let controlOverlay = DefaultControlOverlay()
    private var selectedSampleGroup: VideoSampleGroup = .hls
    private var currentSampleIndex = 0
    private let rates: [Float] = [0.5, 1.0, 1.5, 2.0]
    private let scalingModes: [ScalingMode] = [.aspectFit, .aspectFill, .fill]
    private let fullScreenModes: [FullScreenMode] = [.automatic, .landscape, .portrait]
    private var selectedRate: Float = 1.0
    private var selectedScalingMode: ScalingMode = .aspectFit
    private var selectedFullScreenMode: FullScreenMode = .automatic
    private var disabledGestureTypes: DisableGestureTypes = []
    private var disabledPanMovingDirection: DisablePanMovingDirection = []
    private var isMuted = false
    private var pauseWhenAppResignActive = true
    private var exitFullScreenWhenStop = true
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
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 3.0 / 4.0),

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
        applyPlaybackConfiguration()

        playCurrentVideo()
    }

    private func playCurrentVideo() {
        guard currentSamples.indices.contains(currentSampleIndex) else { return }
        let video = currentSamples[currentSampleIndex]
        player?.stop()
        applyPlaybackConfiguration()
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: video.makeCoverImage(), fullScreenMode: selectedFullScreenMode)
        player?.assetURL = video.url
        applyPlaybackConfiguration()
    }

    private func applyPlaybackConfiguration() {
        player?.rate = selectedRate
        player?.engine.scalingMode = selectedScalingMode
        player?.orientationManager.fullScreenMode = selectedFullScreenMode
        player?.disabledGestureTypes = disabledGestureTypes
        player?.disabledPanMovingDirection = disabledPanMovingDirection
        player?.isMuted = isMuted
        player?.pauseWhenAppResignActive = pauseWhenAppResignActive
        player?.exitFullScreenWhenStop = exitFullScreenWhenStop
        controlOverlay.fullScreenMode = selectedFullScreenMode
    }

    // MARK: - 控件工厂

    private func makeSegmentedControl(items: [String], selectedIndex: Int, action: Selector) -> UISegmentedControl {
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = selectedIndex
        sc.addTarget(self, action: action, for: .valueChanged)
        return sc
    }

    private func makeSwitch(isOn: Bool, action: Selector) -> UISwitch {
        let sw = UISwitch()
        sw.isOn = isOn
        sw.addTarget(self, action: action, for: .valueChanged)
        return sw
    }

    // MARK: - Actions

    @objc private func rateChanged(_ sender: UISegmentedControl) {
        selectedRate = rates[sender.selectedSegmentIndex]
        applyPlaybackConfiguration()
    }

    @objc private func scalingModeChanged(_ sender: UISegmentedControl) {
        selectedScalingMode = scalingModes[sender.selectedSegmentIndex]
        applyPlaybackConfiguration()
    }

    @objc private func fullScreenModeChanged(_ sender: UISegmentedControl) {
        selectedFullScreenMode = fullScreenModes[sender.selectedSegmentIndex]
        applyPlaybackConfiguration()
    }

    @objc private func sampleGroupChanged(_ sender: UISegmentedControl) {
        guard let group = VideoSampleGroup(rawValue: sender.selectedSegmentIndex) else { return }
        selectedSampleGroup = group
        currentSampleIndex = 0
        playCurrentVideo()
        tableView.reloadSections(IndexSet(integer: SettingsSection.videoSource.rawValue), with: .none)
    }

    private func playNextSample() {
        guard !currentSamples.isEmpty else { return }
        currentSampleIndex = (currentSampleIndex + 1) % currentSamples.count
        playCurrentVideo()
        tableView.reloadSections(IndexSet(integer: SettingsSection.videoSource.rawValue), with: .none)
    }

    @objc private func singleTapToggled(_ sender: UISwitch) {
        toggleGesture(.singleTap, enabled: sender.isOn)
    }

    @objc private func doubleTapToggled(_ sender: UISwitch) {
        toggleGesture(.doubleTap, enabled: sender.isOn)
    }

    @objc private func panToggled(_ sender: UISwitch) {
        toggleGesture(.pan, enabled: sender.isOn)
    }

    @objc private func pinchToggled(_ sender: UISwitch) {
        toggleGesture(.pinch, enabled: sender.isOn)
    }

    @objc private func longPressToggled(_ sender: UISwitch) {
        toggleGesture(.longPress, enabled: sender.isOn)
    }

    @objc private func verticalPanToggled(_ sender: UISwitch) {
        togglePanDirection(.vertical, enabled: sender.isOn)
    }

    @objc private func horizontalPanToggled(_ sender: UISwitch) {
        togglePanDirection(.horizontal, enabled: sender.isOn)
    }

    @objc private func muteToggled(_ sender: UISwitch) {
        isMuted = sender.isOn
        applyPlaybackConfiguration()
    }

    @objc private func pauseInBackgroundToggled(_ sender: UISwitch) {
        pauseWhenAppResignActive = sender.isOn
        applyPlaybackConfiguration()
    }

    @objc private func exitFullScreenOnStopToggled(_ sender: UISwitch) {
        exitFullScreenWhenStop = sender.isOn
        applyPlaybackConfiguration()
    }

    private func toggleGesture(_ type: DisableGestureTypes, enabled: Bool) {
        if enabled {
            disabledGestureTypes.remove(type)
        } else {
            disabledGestureTypes.insert(type)
        }
        applyPlaybackConfiguration()
    }

    private func togglePanDirection(_ direction: DisablePanMovingDirection, enabled: Bool) {
        if enabled {
            disabledPanMovingDirection.remove(direction)
        } else {
            disabledPanMovingDirection.insert(direction)
        }
        applyPlaybackConfiguration()
    }
}

// MARK: - Section 定义

private enum SettingsSection: Int, CaseIterable {
    case videoSource = 0
    case rate
    case scalingMode
    case fullScreenMode
    case gestures
    case panDirection
    case other

    var title: String {
        switch self {
        case .videoSource: return "视频素材"
        case .rate: return "播放速率"
        case .scalingMode: return "缩放模式"
        case .fullScreenMode: return "全屏模式"
        case .gestures: return "手势控制"
        case .panDirection: return "滑动方向"
        case .other: return "其他"
        }
    }

    var rowCount: Int {
        switch self {
        case .videoSource: return 2
        case .rate, .scalingMode, .fullScreenMode: return 1
        case .gestures: return 5
        case .panDirection: return 2
        case .other: return 3
        }
    }
}

// MARK: - UITableViewDataSource

extension PlaybackSettingsViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        SettingsSection.allCases.count
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        SettingsSection(rawValue: section)?.title
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        SettingsSection(rawValue: section)?.rowCount ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        cell.accessoryView = nil
        var config = cell.defaultContentConfiguration()

        guard let section = SettingsSection(rawValue: indexPath.section) else {
            cell.contentConfiguration = config
            return cell
        }

        switch section {
        case .videoSource:
            switch indexPath.row {
            case 0:
                config.text = "素材类型"
                cell.contentConfiguration = config
                cell.accessoryView = makeSegmentedControl(
                    items: VideoSampleGroup.allCases.map(\.title),
                    selectedIndex: selectedSampleGroup.rawValue,
                    action: #selector(sampleGroupChanged(_:))
                )
            case 1:
                let video = currentSamples[currentSampleIndex]
                config.text = "切换下一个素材"
                config.secondaryText = video.title
                config.secondaryTextProperties.color = .secondaryLabel
                cell.selectionStyle = .default
                cell.contentConfiguration = config
                cell.accessoryType = .disclosureIndicator
            default:
                cell.contentConfiguration = config
            }

        case .rate:
            config.text = "速率"
            cell.contentConfiguration = config
            cell.accessoryView = makeSegmentedControl(
                items: ["0.5x", "1.0x", "1.5x", "2.0x"],
                selectedIndex: rates.firstIndex(of: selectedRate) ?? 1,
                action: #selector(rateChanged(_:))
            )

        case .scalingMode:
            config.text = "模式"
            cell.contentConfiguration = config
            cell.accessoryView = makeSegmentedControl(
                items: ["AspectFit", "AspectFill", "Fill"],
                selectedIndex: scalingModes.firstIndex(of: selectedScalingMode) ?? 0,
                action: #selector(scalingModeChanged(_:))
            )

        case .fullScreenMode:
            config.text = "模式"
            cell.contentConfiguration = config
            cell.accessoryView = makeSegmentedControl(
                items: ["自动", "横屏", "竖屏"],
                selectedIndex: fullScreenModes.firstIndex(of: selectedFullScreenMode) ?? 0,
                action: #selector(fullScreenModeChanged(_:))
            )

        case .gestures:
            let titles = ["单击", "双击", "滑动", "捏合", "长按"]
            let actions = [
                #selector(singleTapToggled(_:)),
                #selector(doubleTapToggled(_:)),
                #selector(panToggled(_:)),
                #selector(pinchToggled(_:)),
                #selector(longPressToggled(_:)),
            ]
            config.text = titles[indexPath.row]
            cell.contentConfiguration = config
            let gestureTypes: [DisableGestureTypes] = [.singleTap, .doubleTap, .pan, .pinch, .longPress]
            let isEnabled = !disabledGestureTypes.contains(gestureTypes[indexPath.row])
            cell.accessoryView = makeSwitch(isOn: isEnabled, action: actions[indexPath.row])

        case .panDirection:
            let titles = ["垂直滑动", "水平滑动"]
            let actions = [
                #selector(verticalPanToggled(_:)),
                #selector(horizontalPanToggled(_:)),
            ]
            config.text = titles[indexPath.row]
            cell.contentConfiguration = config
            let directions: [DisablePanMovingDirection] = [.vertical, .horizontal]
            let isEnabled = !disabledPanMovingDirection.contains(directions[indexPath.row])
            cell.accessoryView = makeSwitch(isOn: isEnabled, action: actions[indexPath.row])

        case .other:
            switch indexPath.row {
            case 0:
                config.text = "静音"
                cell.contentConfiguration = config
                cell.accessoryView = makeSwitch(isOn: isMuted, action: #selector(muteToggled(_:)))
            case 1:
                config.text = "进入后台暂停"
                cell.contentConfiguration = config
                cell.accessoryView = makeSwitch(isOn: pauseWhenAppResignActive, action: #selector(pauseInBackgroundToggled(_:)))
            case 2:
                config.text = "停止时退出全屏"
                cell.contentConfiguration = config
                cell.accessoryView = makeSwitch(isOn: exitFullScreenWhenStop, action: #selector(exitFullScreenOnStopToggled(_:)))
            default:
                cell.contentConfiguration = config
            }
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension PlaybackSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard SettingsSection(rawValue: indexPath.section) == .videoSource, indexPath.row == 1 else { return }
        playNextSample()
    }
}
