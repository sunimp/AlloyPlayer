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
        public let playerView: AlloyUIKit.AlloyPlayerView
    #endif

    public var configuration = ListPlaybackConfiguration()
    private var selectedID: String?

    #if canImport(UIKit)
        private var playerViewConstraints: [NSLayoutConstraint] = []

        public init(
            playerView: AlloyUIKit.AlloyPlayerView,
            configuration: ListPlaybackConfiguration = .init()
        ) {
            self.playerView = playerView
            self.configuration = configuration
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
                    playerView.stop()
                }
                return nil
            }

            guard selectedID != selected.id else { return selected }

            selectedID = selected.id
            if let container = containerProvider(selected) {
                attachPlayerView(to: container)
            }
            playerView.load(selected.source)
            return selected
        }

        private func attachPlayerView(to container: UIView) {
            NSLayoutConstraint.deactivate(playerViewConstraints)
            playerViewConstraints.removeAll()

            if playerView.superview !== container {
                playerView.removeFromSuperview()
                container.addSubview(playerView)
            }

            playerView.translatesAutoresizingMaskIntoConstraints = false
            playerViewConstraints = [
                playerView.topAnchor.constraint(equalTo: container.topAnchor),
                playerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                playerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                playerView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ]
            NSLayoutConstraint.activate(playerViewConstraints)
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
