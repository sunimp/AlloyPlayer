//
//  CollectionViewPlaybackViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyPlayer
import UIKit

// MARK: - CollectionViewPlaybackViewController

/// CollectionView 列表播放演示
final class CollectionViewPlaybackViewController: UIViewController {
    // MARK: - 子视图

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.dataSource = self
        cv.delegate = self
        cv.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: VideoCollectionViewCell.reuseIdentifier)
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.text = "横向滑动浏览视频，点击播放"
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - 播放器

    private var player: Player?
    private let controlOverlay = DefaultControlOverlay()

    private let videos = VideoResource.allSamples

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
        view.addSubview(hintLabel)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 260),
        ])
    }

    private func setupPlayer() {
        let engine = AVPlayerManager()
        engine.shouldAutoPlay = true

        let player = Player(scrollView: collectionView, engine: engine, containerViewTag: 200)
        player.controlOverlay = controlOverlay
        player.shouldAutoPlay = true
        player.addDeviceOrientationObserver()

        // 配置列表 URL 数据源
        player.sectionAssetURLs = [videos.map(\.url)]

        // 设置横向滚动
        collectionView.scrollViewDirection = .horizontal

        self.player = player
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
        ) as! VideoCollectionViewCell
        cell.configure(with: videos[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CollectionViewPlaybackViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let width = collectionView.bounds.width * 0.8
        return CGSize(width: width, height: 240)
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let video = videos[indexPath.item]
        controlOverlay.resetControlView()
        controlOverlay.show(title: video.title, coverImage: nil, fullScreenMode: .automatic)
        player?.play(at: indexPath, assetURL: video.url)
    }
}
