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

        let video = VideoResource.hlsSamples[0]
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: video.makeCoverImage(), fullScreenMode: .automatic)
        player.assetURL = video.url
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
        let rates: [Float] = [0.5, 1.0, 1.5, 2.0]
        player?.rate = rates[sender.selectedSegmentIndex]
    }

    @objc private func scalingModeChanged(_ sender: UISegmentedControl) {
        let modes: [ScalingMode] = [.aspectFit, .aspectFill, .fill]
        player?.engine.scalingMode = modes[sender.selectedSegmentIndex]
    }

    @objc private func fullScreenModeChanged(_ sender: UISegmentedControl) {
        let modes: [FullScreenMode] = [.automatic, .landscape, .portrait]
        controlOverlay.fullScreenMode = modes[sender.selectedSegmentIndex]
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
        player?.isMuted = sender.isOn
    }

    @objc private func pauseInBackgroundToggled(_ sender: UISwitch) {
        player?.pauseWhenAppResignActive = sender.isOn
    }

    @objc private func exitFullScreenOnStopToggled(_ sender: UISwitch) {
        player?.exitFullScreenWhenStop = sender.isOn
    }

    private func toggleGesture(_ type: DisableGestureTypes, enabled: Bool) {
        guard let player else { return }
        if enabled {
            player.disabledGestureTypes.remove(type)
        } else {
            player.disabledGestureTypes.insert(type)
        }
    }

    private func togglePanDirection(_ direction: DisablePanMovingDirection, enabled: Bool) {
        guard let player else { return }
        if enabled {
            player.disabledPanMovingDirection.remove(direction)
        } else {
            player.disabledPanMovingDirection.insert(direction)
        }
    }
}

// MARK: - Section 定义

private enum SettingsSection: Int, CaseIterable {
    case rate = 0
    case scalingMode
    case fullScreenMode
    case gestures
    case panDirection
    case other

    var title: String {
        switch self {
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
        case .rate:
            config.text = "速率"
            cell.contentConfiguration = config
            cell.accessoryView = makeSegmentedControl(
                items: ["0.5x", "1.0x", "1.5x", "2.0x"],
                selectedIndex: 1,
                action: #selector(rateChanged(_:))
            )

        case .scalingMode:
            config.text = "模式"
            cell.contentConfiguration = config
            cell.accessoryView = makeSegmentedControl(
                items: ["AspectFit", "AspectFill", "Fill"],
                selectedIndex: 0,
                action: #selector(scalingModeChanged(_:))
            )

        case .fullScreenMode:
            config.text = "模式"
            cell.contentConfiguration = config
            cell.accessoryView = makeSegmentedControl(
                items: ["自动", "横屏", "竖屏"],
                selectedIndex: 0,
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
            cell.accessoryView = makeSwitch(isOn: true, action: actions[indexPath.row])

        case .panDirection:
            let titles = ["垂直滑动", "水平滑动"]
            let actions = [
                #selector(verticalPanToggled(_:)),
                #selector(horizontalPanToggled(_:)),
            ]
            config.text = titles[indexPath.row]
            cell.contentConfiguration = config
            cell.accessoryView = makeSwitch(isOn: true, action: actions[indexPath.row])

        case .other:
            switch indexPath.row {
            case 0:
                config.text = "静音"
                cell.contentConfiguration = config
                cell.accessoryView = makeSwitch(isOn: false, action: #selector(muteToggled(_:)))
            case 1:
                config.text = "进入后台暂停"
                cell.contentConfiguration = config
                cell.accessoryView = makeSwitch(isOn: true, action: #selector(pauseInBackgroundToggled(_:)))
            case 2:
                config.text = "停止时退出全屏"
                cell.contentConfiguration = config
                cell.accessoryView = makeSwitch(isOn: true, action: #selector(exitFullScreenOnStopToggled(_:)))
            default:
                cell.contentConfiguration = config
            }
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension PlaybackSettingsViewController: UITableViewDelegate {}
