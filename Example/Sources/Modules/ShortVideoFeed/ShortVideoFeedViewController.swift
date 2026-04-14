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

    private var videos: [VideoItem] = {
        let samples = VideoResource.allSamples
        return (0 ..< 30).map { samples[$0 % samples.count] }
    }()

    // MARK: - 子视图

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

    /// 返回按钮
    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        // 加阴影提高可见度
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.5
        btn.layer.shadowOffset = .zero
        btn.layer.shadowRadius = 4
        return btn
    }()

    // MARK: - 播放器

    private var engine: AVPlayerManager?
    private var cancellables = Set<AnyCancellable>()
    private var currentPlayingIndex: Int = -1

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
        setupBackButton()
        setupEngine()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 首次进入播放第一个
        if currentPlayingIndex < 0 {
            playVideo(at: 0)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        engine?.pause()
    }

    override var prefersStatusBarHidden: Bool {
        false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    deinit {
        MainActor.assumeIsolated {
            engine?.stop()
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

    private func setupBackButton() {
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func setupEngine() {
        let avEngine = AVPlayerManager()
        avEngine.shouldAutoPlay = true
        engine = avEngine
    }

    // MARK: - 播放

    private func playVideo(at index: Int) {
        guard index >= 0, index < videos.count, index != currentPlayingIndex else { return }
        currentPlayingIndex = index

        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = collectionView.cellForItem(at: indexPath) as? ShortVideoFeedCell else { return }

        // 将播放器视图移到当前 cell
        let renderView = engine?.renderView
        renderView?.translatesAutoresizingMaskIntoConstraints = true
        renderView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        renderView?.frame = cell.videoContainerView.bounds
        if let renderView {
            cell.videoContainerView.addSubview(renderView)
        }

        // 播放
        engine?.assetURL = videos[index].url

        // 订阅进度更新到当前 cell
        cancellables.removeAll()
        engine?.playTimePublisher.sink { [weak cell] time in
            guard let cell, time.total > 0 else { return }
            cell.updateProgress(Float(time.current / time.total))
        }.store(in: &cancellables)
    }

    // MARK: - 操作

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
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
        cell.configure(title: video.title, description: video.description, coverColor: video.coverColor)
        cell.onTap = { [weak self] in
            guard let self, let engine = self.engine else { return }
            if engine.isPlaying {
                engine.pause()
                cell.showPauseIndicator()
            } else {
                engine.play()
            }
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ShortVideoFeedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        view.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(round(scrollView.contentOffset.y / scrollView.bounds.height))
        playVideo(at: index)
    }
}
