//
//  ListPlaybackCoordinator.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/13.
//

import AlloyCore
import CoreGraphics

#if canImport(UIKit)
    import AlloyUIKit
    import UIKit
#endif

public struct ListPlaybackConfiguration: Equatable, Sendable {
    public var minimumVisiblePercent: CGFloat
    public var stopsWhenNoCandidateVisible: Bool

    public init(
        minimumVisiblePercent: CGFloat = 0.5,
        stopsWhenNoCandidateVisible: Bool = true
    ) {
        self.minimumVisiblePercent = minimumVisiblePercent
        self.stopsWhenNoCandidateVisible = stopsWhenNoCandidateVisible
    }
}

public struct ListPlaybackCandidate: Equatable, Sendable {
    public var id: String
    public var frame: CGRect
    public var source: PlaybackSource

    public init(id: String, frame: CGRect, source: PlaybackSource) {
        self.id = id
        self.frame = frame
        self.source = source
    }
}

@MainActor
public final class ListPlaybackCoordinator {
    #if canImport(UIKit)
        public let session: PlaybackSession
        public let renderView: AlloyUIKit.AlloyPlayerRenderView
    #endif

    public var configuration = ListPlaybackConfiguration()
    private var selectedID: String?

    #if canImport(UIKit)
        private var renderViewConstraints: [NSLayoutConstraint] = []

        public init(
            session: PlaybackSession,
            renderView: AlloyUIKit.AlloyPlayerRenderView,
            configuration: ListPlaybackConfiguration = .init()
        ) {
            self.session = session
            self.renderView = renderView
            self.configuration = configuration
        }

        public convenience init(
            playerView: AlloyUIKit.AlloyPlayerView,
            configuration: ListPlaybackConfiguration = .init()
        ) {
            self.init(
                session: playerView.session,
                renderView: AlloyUIKit.AlloyPlayerRenderView(session: playerView.session),
                configuration: configuration
            )
        }

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
