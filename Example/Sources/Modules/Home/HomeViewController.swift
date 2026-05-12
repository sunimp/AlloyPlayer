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
            subtitle: "实现 ControlOverlay 协议的极简控制层",
            viewControllerFactory: { CustomControlOverlayViewController() }
        ),
        DemoItem(
            title: "SwiftUI 控制层",
            subtitle: "使用 SwiftUIControlOverlay 构建自定义控制层",
            viewControllerFactory: { SwiftUIControlsDemoViewController() }
        ),
    ]

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AlloyPlayer Demo"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        setupTableHeader()
    }

    // MARK: - 配置

    private func setupTableHeader() {
        let titleLabel = UILabel()
        titleLabel.text = "HTTPMediaCache"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = "开启后，所有 Demo 播放前都会转换为本地缓存代理 URL；关闭则直接播放原始 URL。"
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let headerStack = UIStackView(arrangedSubviews: [textStack, httpMediaCacheSwitch])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 16
        headerStack.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        headerStack.isLayoutMarginsRelativeArrangement = true

        let headerView = UIView()
        headerView.addSubview(headerStack)
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
        ])

        let fittingSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        headerView.frame.size = headerView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        tableView.tableHeaderView = headerView
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
