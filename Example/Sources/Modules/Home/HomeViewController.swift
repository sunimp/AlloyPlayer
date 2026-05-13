//
//  HomeViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import UIKit

// MARK: - HomeViewController

/// 功能列表主页
final class HomeViewController: UITableViewController {
    // MARK: - 子视图

    private lazy var httpMediaCacheSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = DemoPlaybackConfiguration.shared.isHTTPMediaCacheEnabled
        toggle.addTarget(self, action: #selector(httpMediaCacheSwitchChanged(_:)), for: .valueChanged)
        return toggle
    }()

    // MARK: - 数据

    private struct DemoItem {
        let title: String
        let subtitle: String
        let viewControllerFactory: () -> UIViewController
    }

    private lazy var items: [DemoItem] = [
        DemoItem(
            title: "基础播放",
            subtitle: "播放器核心功能与状态展示",
            viewControllerFactory: { BasicPlaybackViewController() }
        ),
        DemoItem(
            title: "短视频滑动",
            subtitle: "类似抖音的竖屏全屏上下滑动播放",
            viewControllerFactory: { ShortVideoFeedViewController() }
        ),
        DemoItem(
            title: "播放配置",
            subtitle: "速率、缩放、手势等参数调节",
            viewControllerFactory: { PlaybackSettingsViewController() }
        ),
        DemoItem(
            title: "TableView 列表播放",
            subtitle: "Feed 流场景的列表播放演示",
            viewControllerFactory: { TableViewPlaybackViewController() }
        ),
        DemoItem(
            title: "CollectionView 列表播放",
            subtitle: "瀑布流布局的列表播放演示",
            viewControllerFactory: { CollectionViewPlaybackViewController() }
        ),
        DemoItem(
            title: "浮动小窗",
            subtitle: "播放器渲染面在页面容器与小窗之间迁移",
            viewControllerFactory: { FloatingPlaybackDemoViewController() }
        ),
        DemoItem(
            title: "全屏模式",
            subtitle: "横屏、竖屏、自动全屏与锁屏",
            viewControllerFactory: { FullScreenModesViewController() }
        ),
        DemoItem(
            title: "自定义控制层",
            subtitle: "实现 UIKitControlOverlay 协议的极简控制层",
            viewControllerFactory: { CustomControlOverlayViewController() }
        ),
        DemoItem(
            title: "SwiftUI 控制层",
            subtitle: "使用 AlloySwiftUIPlayerView 构建自定义控制层",
            viewControllerFactory: { SwiftUIControlsDemoViewController() }
        ),
    ]

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AlloyPlayer Demo"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        setupNavigationItems()
    }

    // MARK: - 配置

    private func setupNavigationItems() {
        let titleLabel = UILabel()
        titleLabel.text = "缓存"
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, httpMediaCacheSwitch])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 8
        headerStack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        headerStack.isLayoutMarginsRelativeArrangement = true

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: headerStack)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = items[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.secondaryText = item.subtitle
        config.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = items[indexPath.row].viewControllerFactory()
        vc.title = items[indexPath.row].title
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Actions

    @objc private func httpMediaCacheSwitchChanged(_ sender: UISwitch) {
        DemoPlaybackConfiguration.shared.isHTTPMediaCacheEnabled = sender.isOn
    }
}
