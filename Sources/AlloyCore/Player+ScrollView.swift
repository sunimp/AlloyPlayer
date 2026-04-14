//
//  Player+ScrollView.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import Combine
    import UIKit

    // MARK: - 列表播放扩展

    public extension Player {
        // MARK: - 小窗

        /// 小窗视图
        var floatingView: FloatingView? {
            _floatingView
        }

        /// 小窗是否可见
        var isFloatingViewVisible: Bool {
            _isFloatingViewVisible
        }

        /// 将播放器添加到 Cell
        func addPlayerView(to cell: UIView) {
            let container = cell.viewWithTag(_containerViewTag)
            if let container {
                containerView = container
            }
        }

        /// 将播放器添加到指定容器视图
        func addPlayerView(toContainer containerView: UIView) {
            self.containerView = containerView
        }

        /// 将播放器添加到小窗
        func addPlayerViewToFloatingView() {
            guard let view = ensureFloatingView() else { return }
            _isFloatingViewVisible = true
            view.addSubview(engine.renderView)
            engine.renderView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                engine.renderView.topAnchor.constraint(equalTo: view.topAnchor),
                engine.renderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                engine.renderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                engine.renderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            controlOverlay?.player(self, floatViewShow: true)
        }

        // MARK: - 列表配置

        /// 是否自动播放
        var shouldAutoPlay: Bool {
            get { _shouldAutoPlay }
            set { _shouldAutoPlay = newValue }
        }

        /// 移动网络下自动播放
        var autoPlayOnWWAN: Bool {
            get { _autoPlayOnWWAN }
            set { _autoPlayOnWWAN = newValue }
        }

        /// 当前正在播放的 IndexPath
        var playingIndexPath: IndexPath? {
            _playingIndexPath
        }

        /// 应该播放的 IndexPath
        var shouldPlayIndexPath: IndexPath? {
            _shouldPlayIndexPath
        }

        /// 容器视图 Tag
        var containerViewTag: Int {
            _containerViewTag
        }

        /// 不可见时停止播放
        var stopWhileNotVisible: Bool {
            get { _stopWhileNotVisible }
            set { _stopWhileNotVisible = newValue }
        }

        /// 消失多少百分比后触发消失回调
        var disappearPercent: CGFloat {
            get { _disappearPercent }
            set { _disappearPercent = newValue }
        }

        /// 出现多少百分比后触发出现回调
        var appearPercent: CGFloat {
            get { _appearPercent }
            set { _appearPercent = newValue }
        }

        /// 分段 URL 数据源
        var sectionAssetURLs: [[URL]]? {
            get { _sectionAssetURLs }
            set { _sectionAssetURLs = newValue }
        }

        // MARK: - 列表播放事件 Publishers

        var playerAppearingPublisher: AnyPublisher<(IndexPath, CGFloat), Never> {
            _playerAppearing.eraseToAnyPublisher()
        }

        var playerDisappearingPublisher: AnyPublisher<(IndexPath, CGFloat), Never> {
            _playerDisappearing.eraseToAnyPublisher()
        }

        var playerWillAppearPublisher: AnyPublisher<IndexPath, Never> {
            _playerWillAppear.eraseToAnyPublisher()
        }

        var playerDidAppearPublisher: AnyPublisher<IndexPath, Never> {
            _playerDidAppear.eraseToAnyPublisher()
        }

        var playerWillDisappearPublisher: AnyPublisher<IndexPath, Never> {
            _playerWillDisappear.eraseToAnyPublisher()
        }

        var playerDidDisappearPublisher: AnyPublisher<IndexPath, Never> {
            _playerDidDisappear.eraseToAnyPublisher()
        }

        var scrollViewDidEndScrollingPublisher: AnyPublisher<IndexPath, Never> {
            _scrollViewDidEndScrolling.eraseToAnyPublisher()
        }

        // MARK: - 播放指定位置

        /// 播放指定 IndexPath
        func play(at indexPath: IndexPath) {
            play(at: indexPath, scrollTo: .none, animated: false)
        }

        /// 播放指定 IndexPath 并滚动
        func play(at indexPath: IndexPath, scrollTo position: ScrollAnchor, animated: Bool) async {
            _playingIndexPath = indexPath
            if let scrollView, position != .none {
                await scrollView.scroll(to: indexPath, at: position, animated: animated)
            }
            if let cell = scrollView?.cell(at: indexPath) {
                addPlayerView(to: cell)
            }
            if let urls = _sectionAssetURLs,
               indexPath.section < urls.count,
               indexPath.row < urls[indexPath.section].count
            {
                assetURL = urls[indexPath.section][indexPath.row]
            }
        }

        /// 播放指定 IndexPath 和 URL
        func play(at indexPath: IndexPath, assetURL: URL) {
            _playingIndexPath = indexPath
            if let cell = scrollView?.cell(at: indexPath) {
                addPlayerView(to: cell)
            }
            self.assetURL = assetURL
        }

        /// 播放指定 IndexPath、URL 并滚动
        func play(at indexPath: IndexPath, assetURL: URL, scrollTo position: ScrollAnchor, animated: Bool) async {
            _playingIndexPath = indexPath
            if let scrollView, position != .none {
                await scrollView.scroll(to: indexPath, at: position, animated: animated)
            }
            if let cell = scrollView?.cell(at: indexPath) {
                addPlayerView(to: cell)
            }
            self.assetURL = assetURL
        }

        // MARK: - 滚动过滤

        /// 滚动停止时过滤应播放的 Cell
        func filterShouldPlayCellWhileScrolled() -> IndexPath? {
            // 简化实现：查找最靠近屏幕中心的 Cell
            guard let scrollView else { return nil }
            let visibleCells: [IndexPath]
            if let tableView = scrollView as? UITableView {
                visibleCells = tableView.indexPathsForVisibleRows ?? []
            } else if let collectionView = scrollView as? UICollectionView {
                visibleCells = collectionView.indexPathsForVisibleItems
            } else {
                return nil
            }
            return visibleCells.first
        }

        /// 滚动中过滤应播放的 Cell
        func filterShouldPlayCellWhileScrolling() -> IndexPath? {
            filterShouldPlayCellWhileScrolled()
        }

        /// 停止当前播放视图
        func stopCurrentPlayingView() {
            stop()
            _isFloatingViewVisible = false
            _floatingView?.removeFromSuperview()
        }

        /// 停止当前播放 Cell
        func stopCurrentPlayingCell() {
            stop()
            _playingIndexPath = nil
        }

        // MARK: - 辅助

        private func ensureFloatingView() -> FloatingView? {
            if let existing = _floatingView { return existing }
            guard let keyWindow = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first(where: { $0.isKeyWindow })
            else { return nil }

            let floatView = FloatingView(frame: CGRect(x: keyWindow.bounds.width - 212, y: keyWindow.bounds.height - 168, width: 192, height: 108))
            floatView.parentView = keyWindow
            floatView.safeInsets = keyWindow.safeAreaInsets
            _floatingView = floatView
            return floatView
        }

        private func play(at indexPath: IndexPath, scrollTo position: ScrollAnchor, animated: Bool) {
            Task {
                await play(at: indexPath, scrollTo: position, animated: animated)
            }
        }
    }
#endif
