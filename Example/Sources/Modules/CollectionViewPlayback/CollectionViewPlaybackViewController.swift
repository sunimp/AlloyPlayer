//
//  CollectionViewPlaybackViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyPlayer
import UIKit

// MARK: - CollectionViewPlaybackViewController

/// CollectionView 瀑布流列表播放演示
final class CollectionViewPlaybackViewController: UIViewController {
    // MARK: - 子视图

    private lazy var collectionView: UICollectionView = {
        let layout = CHTCollectionViewWaterfallLayout()
        layout.columnCount = 2
        layout.minimumColumnSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.dataSource = self
        cv.delegate = self
        cv.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: VideoCollectionViewCell.reuseIdentifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    // MARK: - 播放器

    private let session = AlloyPlayerFactory.makeDefaultSession()
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

    /// 为瀑布流生成随机高度（模拟不同视频宽高比）
    private lazy var itemHeights: [CGFloat] = videos.map { _ in CGFloat.random(in: 180 ... 300) }

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "CollectionView 列表播放"
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
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupPlayer() {
        controlOverlay.autoHideInterval = 8
        listPlayback.configuration.minimumVisiblePercent = 0.4
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
        let video = videos[indexPath.item]
        selectedIndexPath = indexPath
        isFloatingSuppressedForCurrentItem = false
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: video.makeCoverImage(), fullScreenMode: .automatic)
        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak self] in
            guard let self,
                  let cell = collectionView.cellForItem(at: indexPath) as? VideoCollectionViewCell
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
                viewport: collectionView.bounds,
                containerProvider: { _ in cell.videoContainerView }
            )
            attachInlineControls(to: cell.videoContainerView)
            refreshFloatingPlaybackVisibility()
        }
    }

    private func refreshFloatingPlaybackVisibility() {
        guard let selectedIndexPath, selectedIndexPath.item < videos.count else {
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
              let cell = collectionView.cellForItem(at: selectedIndexPath) as? VideoCollectionViewCell
        else { return }

        let candidate = makeCandidate(indexPath: selectedIndexPath, cell: cell, source: selectedSource)
        UIView.performWithoutAnimation {
            _ = listPlayback.update(
                candidates: [candidate],
                viewport: collectionView.bounds,
                containerProvider: { _ in cell.videoContainerView }
            )
            attachInlineControls(to: cell.videoContainerView)
            cell.videoContainerView.layoutIfNeeded()
        }
    }

    private func attachInlineControls(to container: UIView) {
        NSLayoutConstraint.deactivate(inlineControlConstraints)
        inlineControlConstraints.removeAll()
        if inlineControlView.superview !== container {
            inlineControlView.removeFromSuperview()
            inlineControlView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(inlineControlView)
        }
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
        guard let cell = collectionView.cellForItem(at: indexPath) as? VideoCollectionViewCell else {
            return 0
        }
        let frame = cell.videoContainerView.convert(cell.videoContainerView.bounds, to: collectionView)
        return visiblePercent(of: frame, in: collectionView.bounds)
    }

    private func makeCandidate(
        indexPath: IndexPath,
        cell: VideoCollectionViewCell,
        source: PlaybackSource
    ) -> ListPlaybackCandidate {
        let frame = cell.videoContainerView.convert(cell.videoContainerView.bounds, to: collectionView)
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

// MARK: - UICollectionViewDataSource

extension CollectionViewPlaybackViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        videos.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        guard let videoCell = cell as? VideoCollectionViewCell else {
            assertionFailure("无法复用 VideoCollectionViewCell")
            return cell
        }
        videoCell.configure(with: videos[indexPath.item])
        return videoCell
    }
}

// MARK: - CHTCollectionViewDelegateWaterfallLayout

extension CollectionViewPlaybackViewController: CHTCollectionViewDelegateWaterfallLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout _: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let columnCount: CGFloat = 2
        let inset: CGFloat = 8
        let spacing: CGFloat = 8
        let totalWidth = collectionView.bounds.width - inset * 2 - spacing * (columnCount - 1)
        let itemWidth = totalWidth / columnCount
        return CGSize(width: itemWidth, height: itemHeights[indexPath.item])
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
