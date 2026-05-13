//
//  ListPlaybackCoordinator.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/13.
//

import AlloyCore
import CoreGraphics

#if canImport(UIKit)
    import AlloyPlayerUIKit
    import UIKit
#endif

/// 列表自动播放配置。
public struct ListPlaybackConfiguration: Equatable, Sendable {
    /// 候选项成为播放目标所需的最小可见比例。
    public var minimumVisiblePercent: CGFloat

    /// 没有可见候选项时是否停止播放。
    public var stopsWhenNoCandidateVisible: Bool

    /// 创建列表自动播放配置。
    public init(
        minimumVisiblePercent: CGFloat = 0.5,
        stopsWhenNoCandidateVisible: Bool = true
    ) {
        self.minimumVisiblePercent = minimumVisiblePercent
        self.stopsWhenNoCandidateVisible = stopsWhenNoCandidateVisible
    }
}

/// 列表自动播放候选项。
public struct ListPlaybackCandidate: Equatable, Sendable {
    /// 候选项唯一标识。
    public var id: String

    /// 候选项在视口坐标系中的布局区域。
    public var frame: CGRect

    /// 候选项对应的播放源。
    public var source: PlaybackSource

    /// 创建列表自动播放候选项。
    public init(id: String, frame: CGRect, source: PlaybackSource) {
        self.id = id
        self.frame = frame
        self.source = source
    }
}

/// 列表自动播放协调器。
@MainActor
public final class ListPlaybackCoordinator {
    #if canImport(UIKit)
        /// 列表播放使用的播放会话。
        public let session: PlaybackSession

        /// 复用并挂载到当前可见候选项上的渲染视图。
        public let renderView: AlloyPlayerUIKit.AlloyPlayerRenderView
    #endif

    /// 列表自动播放配置。
    public var configuration = ListPlaybackConfiguration()
    private var selectedID: String?

    #if canImport(UIKit)
        private var renderViewConstraints: [NSLayoutConstraint] = []

        /// 使用既有播放会话和渲染视图创建协调器。
        public init(
            session: PlaybackSession,
            renderView: AlloyPlayerUIKit.AlloyPlayerRenderView,
            configuration: ListPlaybackConfiguration = .init()
        ) {
            self.session = session
            self.renderView = renderView
            self.configuration = configuration
        }

        /// 使用完整播放器视图创建协调器。
        public convenience init(
            playerView: AlloyPlayerUIKit.AlloyPlayerView,
            configuration: ListPlaybackConfiguration = .init()
        ) {
            self.init(
                session: playerView.session,
                renderView: AlloyPlayerUIKit.AlloyPlayerRenderView(session: playerView.session),
                configuration: configuration
            )
        }

        /// 根据候选项可见比例更新当前播放目标。
        @discardableResult
        public func update(
            candidates: [ListPlaybackCandidate],
            viewport: CGRect,
            containerProvider: (ListPlaybackCandidate) -> UIView?
        ) -> ListPlaybackCandidate? {
            guard let selected = Self.selectCandidate(
                in: candidates,
                viewport: viewport,
                minimumVisiblePercent: configuration.minimumVisiblePercent
            ) else {
                selectedID = nil
                if configuration.stopsWhenNoCandidateVisible {
                    session.stop()
                }
                return nil
            }

            let container = containerProvider(selected)
            guard selectedID != selected.id else {
                if let container, renderView.superview !== container {
                    attachRenderView(to: container)
                }
                return selected
            }

            selectedID = selected.id
            if let container {
                attachRenderView(to: container)
            }
            session.load(selected.source)
            return selected
        }

        private func attachRenderView(to container: UIView) {
            UIView.performWithoutAnimation {
                NSLayoutConstraint.deactivate(renderViewConstraints)
                renderViewConstraints.removeAll()

                if renderView.superview !== container {
                    renderView.removeFromSuperview()
                    container.addSubview(renderView)
                }

                renderView.translatesAutoresizingMaskIntoConstraints = false
                renderViewConstraints = [
                    renderView.topAnchor.constraint(equalTo: container.topAnchor),
                    renderView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    renderView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    renderView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                ]
                NSLayoutConstraint.activate(renderViewConstraints)
                renderView.activateRenderSurface()
                container.layoutIfNeeded()
            }
        }
    #endif

    /// 从候选项中选择可见比例最高且满足阈值的播放目标。
    public nonisolated static func selectCandidate(
        in candidates: [ListPlaybackCandidate],
        viewport: CGRect,
        minimumVisiblePercent: CGFloat = 0
    ) -> ListPlaybackCandidate? {
        candidates
            .map { candidate in
                (candidate: candidate, percent: VisibilityEvaluator.visiblePercent(of: candidate.frame, in: viewport))
            }
            .filter { $0.percent >= minimumVisiblePercent && $0.percent > 0 }
            .max { lhs, rhs in
                lhs.percent < rhs.percent
            }?
            .candidate
    }
}
