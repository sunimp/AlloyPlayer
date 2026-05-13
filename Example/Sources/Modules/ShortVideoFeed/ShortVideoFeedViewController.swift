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
        let samples = VideoResource.shortVideoSamples
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

    private let session = AlloyPlayerFactory.makeDefaultSession()
    private lazy var playerView = AlloyPlayerView(session: session)
    private var cancellables = Set<AnyCancellable>()
    private var playbackTask: Task<Void, Never>?
    private var currentPlayingIndex: Int = -1
    private var playerViewConstraints: [NSLayoutConstraint] = []

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
        setupBackButton()
        setupPlayerView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // 隐藏导航栏后恢复侧滑返回手势
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
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
        playerView.pause()
    }

    override var prefersStatusBarHidden: Bool {
        false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    deinit {
        MainActor.assumeIsolated {
            playbackTask?.cancel()
            playerView.stop()
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

    private func setupPlayerView() {
        playerView.configuration.pausesWhenDetachedFromWindow = false
    }

    // MARK: - 播放

    private func playVideo(at index: Int) {
        guard index >= 0, index < videos.count, index != currentPlayingIndex else { return }
        currentPlayingIndex = index

        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = collectionView.cellForItem(at: indexPath) as? ShortVideoFeedCell else { return }

        // 确保布局完成
        cell.layoutIfNeeded()

        // 将播放器视图移到当前 cell
        NSLayoutConstraint.deactivate(playerViewConstraints)
        playerView.removeFromSuperview()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        cell.videoContainerView.addSubview(playerView)
        playerViewConstraints = [
            playerView.topAnchor.constraint(equalTo: cell.videoContainerView.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: cell.videoContainerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: cell.videoContainerView.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: cell.videoContainerView.bottomAnchor),
        ]
        NSLayoutConstraint.activate(playerViewConstraints)

        // 重置进度并隐藏封面
        cell.updateProgress(0)
        cell.updateBufferProgress(0)
        cell.setBuffering(false)
        cell.setPausedIndicatorVisible(false)
        cell.hideCover()

        // 播放
        playbackTask?.cancel()
        let video = videos[index]
        playbackTask = Task { @MainActor [weak self, weak playerView] in
            guard let self, let playerView, self.currentPlayingIndex == index else { return }
            do {
                _ = try await playerView.prepareDemoPlayback(originalURL: video.url)
            } catch {
                playerView.load(PlaybackSource(url: video.url))
            }
        }

        // 订阅进度更新到当前 cell
        cancellables.removeAll()
        session.statePublisher.sink { [weak cell] snapshot in
            guard let cell else { return }
            let engine = snapshot.engine
            if engine.duration > 0 {
                cell.syncPlaybackProgress(Float(engine.currentTime / engine.duration))
                cell.updateBufferProgress(Float(engine.bufferedTime / engine.duration))
            }
            if engine.loadState.contains(.playable) || engine.loadState.contains(.playthroughOK) {
                cell.setBuffering(false)
            }
            if engine.loadState.contains(.stalled), engine.playbackState == .playing {
                cell.setPausedIndicatorVisible(false)
                cell.setBuffering(true)
            }
            if engine.loadState.contains(.preparing) {
                cell.setPausedIndicatorVisible(false)
                cell.setBuffering(true)
            }

            switch engine.playbackState {
            case .paused:
                cell.setPausedIndicatorVisible(true)
            default:
                cell.setPausedIndicatorVisible(false)
            }
        }.store(in: &cancellables)
    }

    private func seekCurrentVideo(to progress: Float) {
        guard session.state.engine.duration > 0 else { return }
        let seekTime = session.state.engine.duration * TimeInterval(progress)
        Task {
            _ = await session.seek(to: seekTime)
            session.play()
        }
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
        )
        guard let feedCell = cell as? ShortVideoFeedCell else {
            assertionFailure("Failed to reuse ShortVideoFeedCell")
            return cell
        }
        let video = videos[indexPath.item]
        feedCell.configure(title: video.title, description: video.description, coverColor: video.coverColor)
        feedCell.onTap = { [weak self, weak feedCell] in
            guard let self else { return }
            if session.state.engine.playbackState == .playing {
                session.pause()
            } else {
                feedCell?.setPausedIndicatorVisible(false)
                session.play()
            }
        }
        feedCell.onSeek = { [weak self] progress in
            self?.seekCurrentVideo(to: progress)
        }
        return feedCell
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
