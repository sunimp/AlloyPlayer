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
    private let fullscreenCoordinator = FullscreenCoordinator()
    private let controlOverlay = DefaultControlOverlay()
    private lazy var renderView = AlloyPlayerRenderView(session: session)
    private lazy var inlineControlView = AlloyPlayerControlView(session: session, controlOverlay: controlOverlay)
    private lazy var listPlayback = ListPlaybackCoordinator(session: session, renderView: renderView)
    private lazy var floatingPlayback = FloatingPlaybackCoordinator(session: session, renderView: renderView)
    private var inlineControlConstraints: [NSLayoutConstraint] = []
    private var playbackTask: Task<Void, Never>?
    private var selectedIndexPath: IndexPath?
    private var selectedSource: PlaybackSource?
    private var isFloatingPlaybackEnabled = true
    private var isFloatingSuppressedForCurrentItem = false
    private let floatingAppearVisiblePercent: CGFloat = 0.1
    private let floatingDisappearVisiblePercent: CGFloat = 0.9

    private lazy var floatingSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = isFloatingPlaybackEnabled
        toggle.addTarget(self, action: #selector(floatingSwitchChanged(_:)), for: .valueChanged)
        return toggle
    }()

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
            floatingPlayback.hide()
            session.stop()
        }
    }

    // MARK: - 配置

    private func setupUI() {
        setupNavigationItems()
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupPlayer() {
        inlineControlView.fullscreenCoordinator = fullscreenCoordinator
        listPlayback.configuration.minimumVisiblePercent = 0.5
        floatingPlayback.setCloseHandler { [weak self] in
            guard let self else { return }
            isFloatingSuppressedForCurrentItem = true
            session.pause()
        }
    }

    private func setupNavigationItems() {
        let titleLabel = UILabel()
        titleLabel.text = "小窗"
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, floatingSwitch])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        stackView.isLayoutMarginsRelativeArrangement = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stackView)
    }

    private func startPlayback(at indexPath: IndexPath) {
        guard selectedIndexPath != indexPath || selectedSource == nil else { return }

        let video = videos[indexPath.row]
        selectedIndexPath = indexPath
        isFloatingSuppressedForCurrentItem = false
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: video.makeCoverImage(), fullScreenMode: .automatic)
        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak self] in
            guard let self,
                  let cell = tableView.cellForRow(at: indexPath) as? VideoTableViewCell
            else { return }

            let source: PlaybackSource
            do {
                source = try await DemoPlaybackConfiguration.shared.playbackSource(for: video.url)
            } catch {
                source = PlaybackSource(url: video.url)
            }

            selectedSource = source
            let candidate = makeCandidate(indexPath: indexPath, cell: cell, source: source)
            _ = listPlayback.update(
                candidates: [candidate],
                viewport: tableView.bounds,
                containerProvider: { _ in cell.videoContainerView }
            )
            attachInlineControls(to: cell.videoContainerView)
            refreshFloatingPlaybackVisibility()
        }
    }

    private func refreshFloatingPlaybackVisibility() {
        guard let selectedIndexPath, selectedIndexPath.row < videos.count else {
            floatingPlayback.hide()
            return
        }

        let visiblePercent = selectedVideoVisiblePercent(at: selectedIndexPath)
        if visiblePercent >= floatingDisappearVisiblePercent {
            isFloatingSuppressedForCurrentItem = false
            if floatingPlayback.isVisible {
                floatingPlayback.hide()
            }
            attachInlinePlaybackIfPossible()
            return
        }

        guard visiblePercent <= floatingAppearVisiblePercent else {
            return
        }

        guard isFloatingPlaybackEnabled, !isFloatingSuppressedForCurrentItem else {
            if floatingPlayback.isVisible {
                floatingPlayback.hide()
            }
            if visiblePercent <= 0 {
                session.pause()
            } else {
                attachInlinePlaybackIfPossible()
            }
            return
        }

        guard !floatingPlayback.isVisible else { return }
        detachInlineControls()
        floatingPlayback.show(in: view, frame: defaultFloatingFrame())
    }

    private func attachInlinePlaybackIfPossible() {
        guard let selectedIndexPath,
              let selectedSource,
              let cell = tableView.cellForRow(at: selectedIndexPath) as? VideoTableViewCell
        else { return }

        let candidate = makeCandidate(indexPath: selectedIndexPath, cell: cell, source: selectedSource)
        UIView.performWithoutAnimation {
            _ = listPlayback.update(
                candidates: [candidate],
                viewport: tableView.bounds,
                containerProvider: { _ in cell.videoContainerView }
            )
            attachInlineControls(to: cell.videoContainerView)
            cell.videoContainerView.layoutIfNeeded()
        }
    }

    private func attachInlineControls(to container: UIView) {
        guard inlineControlView.superview !== container else { return }

        NSLayoutConstraint.deactivate(inlineControlConstraints)
        inlineControlConstraints.removeAll()
        inlineControlView.removeFromSuperview()
        inlineControlView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(inlineControlView)
        inlineControlConstraints = [
            inlineControlView.topAnchor.constraint(equalTo: container.topAnchor),
            inlineControlView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            inlineControlView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            inlineControlView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ]
        NSLayoutConstraint.activate(inlineControlConstraints)
    }

    private func detachInlineControls() {
        NSLayoutConstraint.deactivate(inlineControlConstraints)
        inlineControlConstraints.removeAll()
        inlineControlView.removeFromSuperview()
    }

    private func selectedVideoVisiblePercent(at indexPath: IndexPath) -> CGFloat {
        guard let cell = tableView.cellForRow(at: indexPath) as? VideoTableViewCell else {
            return 0
        }
        let frame = cell.videoContainerView.convert(cell.videoContainerView.bounds, to: tableView)
        return visiblePercent(of: frame, in: tableView.bounds)
    }

    private func makeCandidate(
        indexPath: IndexPath,
        cell: VideoTableViewCell,
        source: PlaybackSource
    ) -> ListPlaybackCandidate {
        let frame = cell.videoContainerView.convert(cell.videoContainerView.bounds, to: tableView)
        return ListPlaybackCandidate(id: indexPath.description, frame: frame, source: source)
    }

    private func visiblePercent(of itemFrame: CGRect, in viewport: CGRect) -> CGFloat {
        guard itemFrame.width > 0, itemFrame.height > 0, viewport.width > 0, viewport.height > 0 else {
            return 0
        }

        let intersection = itemFrame.intersection(viewport)
        guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else {
            return 0
        }

        return min(max(intersection.width * intersection.height / (itemFrame.width * itemFrame.height), 0), 1)
    }

    private func defaultFloatingFrame() -> CGRect {
        let width = min(view.bounds.width - 32, 200)
        let height = width * 9.0 / 16.0
        return CGRect(
            x: view.bounds.width - width - 16,
            y: view.bounds.height - height - view.safeAreaInsets.bottom - 24,
            width: width,
            height: height
        )
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
            assertionFailure("Failed to reuse VideoTableViewCell")
            return cell
        }
        videoCell.configure(with: videos[indexPath.row])
        return videoCell
    }
}

// MARK: - UITableViewDelegate

extension TableViewPlaybackViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        startPlayback(at: indexPath)
    }

    func scrollViewDidScroll(_: UIScrollView) {
        refreshFloatingPlaybackVisibility()
    }

    func scrollViewDidEndDragging(_: UIScrollView, willDecelerate _: Bool) {
        refreshFloatingPlaybackVisibility()
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        refreshFloatingPlaybackVisibility()
    }

    @objc private func floatingSwitchChanged(_ sender: UISwitch) {
        isFloatingPlaybackEnabled = sender.isOn
        if sender.isOn {
            isFloatingSuppressedForCurrentItem = false
        }
        refreshFloatingPlaybackVisibility()
    }
}
