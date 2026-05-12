//
//  ListPlaybackCoordinator.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/12.
//

import CoreGraphics
import Foundation

#if canImport(UIKit)
    import AlloyCore
    import UIKit
#endif

/// 列表播放候选项。
public struct ListPlaybackCandidate: Equatable {
    public let indexPath: IndexPath
    public let frame: CGRect
    public let assetURL: URL?

    public init(indexPath: IndexPath, frame: CGRect, assetURL: URL? = nil) {
        self.indexPath = indexPath
        self.frame = frame
        self.assetURL = assetURL
    }
}

/// 列表播放协调器。
public final class ListPlaybackCoordinator {
    #if canImport(UIKit)
        private weak var player: Player?

        @MainActor
        public init(player: Player) {
            self.player = player
        }
    #endif

    public static func selectCandidate(
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

    #if canImport(UIKit)
        @MainActor
        public func play(_ candidate: ListPlaybackCandidate, in containerView: UIView) {
            guard let player else { return }
            player.attach(to: containerView)
            if let assetURL = candidate.assetURL {
                player.play(at: candidate.indexPath, assetURL: assetURL)
            } else {
                player.play(at: candidate.indexPath)
            }
        }

        @discardableResult
        @MainActor
        public func playBestCandidate(
            in candidates: [ListPlaybackCandidate],
            viewport: CGRect,
            minimumVisiblePercent: CGFloat = 0
        ) -> ListPlaybackCandidate? {
            guard let selected = Self.selectCandidate(
                in: candidates,
                viewport: viewport,
                minimumVisiblePercent: minimumVisiblePercent
            ) else {
                return nil
            }

            if let assetURL = selected.assetURL {
                player?.play(at: selected.indexPath, assetURL: assetURL)
            } else {
                player?.play(at: selected.indexPath)
            }

            return selected
        }

        @discardableResult
        @MainActor
        public func playBestCandidate(
            in candidates: [ListPlaybackCandidate],
            viewport: CGRect,
            minimumVisiblePercent: CGFloat = 0,
            containerProvider: (ListPlaybackCandidate) -> UIView?
        ) -> ListPlaybackCandidate? {
            guard let selected = Self.selectCandidate(
                in: candidates,
                viewport: viewport,
                minimumVisiblePercent: minimumVisiblePercent
            ) else {
                return nil
            }

            if let containerView = containerProvider(selected) {
                play(selected, in: containerView)
            } else if let assetURL = selected.assetURL {
                player?.play(at: selected.indexPath, assetURL: assetURL)
            } else {
                player?.play(at: selected.indexPath)
            }

            return selected
        }
    #endif
}
