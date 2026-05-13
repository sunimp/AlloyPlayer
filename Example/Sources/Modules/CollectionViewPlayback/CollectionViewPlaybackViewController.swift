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
    private lazy var playerView = AlloyPlayerView(session: session)
    private lazy var listPlayback = ListPlaybackCoordinator(playerView: playerView)
    private let controlOverlay = DefaultControlOverlay()
    private var playbackTask: Task<Void, Never>?

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
            playerView.stop()
        }
    }

    // MARK: - 配置

    private func setupUI() {
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupPlayer() {
        playerView.controlOverlay = controlOverlay
        listPlayback.configuration.minimumVisiblePercent = 0.4
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
        let video = videos[indexPath.item]
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: video.makeCoverImage(), fullScreenMode: .automatic)
        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak self] in
            guard let self,
                  let cell = collectionView.cellForItem(at: indexPath) as? VideoCollectionViewCell
            else { return }
            do {
                let source = try await DemoPlaybackConfiguration.shared.playbackSource(for: video.url)
                let candidate = ListPlaybackCandidate(id: indexPath.description, frame: cell.frame, source: source)
                _ = listPlayback.update(
                    candidates: [candidate],
                    viewport: collectionView.bounds,
                    containerProvider: { _ in cell.videoContainerView }
                )
            } catch {
                let candidate = ListPlaybackCandidate(id: indexPath.description, frame: cell.frame, source: PlaybackSource(url: video.url))
                _ = listPlayback.update(
                    candidates: [candidate],
                    viewport: collectionView.bounds,
                    containerProvider: { _ in cell.videoContainerView }
                )
            }
        }
    }
}
