//
//  ShortVideoFeedViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyPlayer
import Combine
import UIKit

// MARK: - ShortVideoFeedViewController

/// 抖音风格竖屏全屏滚动播放
final class ShortVideoFeedViewController: UIViewController {
    // MARK: - 数据源

    /// 循环 VideoResource.allSamples 到 30 条
    private var videos: [VideoItem] = {
        let samples = VideoResource.allSamples
        return (0 ..< 30).map { samples[$0 % samples.count] }
    }()

    // MARK: - 子视图

    /// 全屏 UICollectionView，垂直分页
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.backgroundColor = .black
        cv.contentInsetAdjustmentBehavior = .never
        cv.register(ShortVideoFeedCell.self, forCellWithReuseIdentifier: ShortVideoFeedCell.reuseIdentifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    // MARK: - 播放器

    private var player: Player?
    private var cancellables = Set<AnyCancellable>()
    private var currentPlayingIndex: Int = 0

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
        setupPlayer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        player?.isViewControllerDisappear = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        player?.isViewControllerDisappear = true
    }

    override var prefersStatusBarHidden: Bool {
        false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    deinit {
        MainActor.assumeIsolated {
            player?.stop()
        }
    }

    // MARK: - 配置

    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupPlayer() {
        let engine = AVPlayerManager()
        engine.shouldAutoPlay = true

        // 使用列表模式，containerViewTag = 300
        let player = Player(scrollView: collectionView, engine: engine, containerViewTag: 300)

        // 使用极简控制层
        let overlay = MinimalControlOverlay()
        player.controlOverlay = overlay

        // 配置
        player.shouldAutoPlay = true
        player.stopWhileNotVisible = true
        player.disappearPercent = 0.5

        self.player = player

        // 首次加载后播放第一个
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.playVideo(at: 0)
        }
    }

    // MARK: - 播放

    private func playVideo(at index: Int) {
        guard index >= 0, index < videos.count else { return }
        currentPlayingIndex = index
        let indexPath = IndexPath(item: index, section: 0)
        player?.play(at: indexPath, assetURL: videos[index].url)
    }
}

// MARK: - UICollectionViewDataSource

extension ShortVideoFeedViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        videos.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ShortVideoFeedCell.reuseIdentifier,
            for: indexPath
        ) as! ShortVideoFeedCell
        let video = videos[indexPath.item]
        cell.configure(title: video.title, description: video.description)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ShortVideoFeedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        view.bounds.size
    }

    /// 翻页后自动播放
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(round(scrollView.contentOffset.y / scrollView.bounds.height))
        if index != currentPlayingIndex {
            playVideo(at: index)
        }
    }
}
