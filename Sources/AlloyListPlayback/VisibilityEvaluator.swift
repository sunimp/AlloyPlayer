//
//  VisibilityEvaluator.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/12.
//

import CoreGraphics

/// 计算列表元素在视口中的可见比例。
public enum VisibilityEvaluator {
    public static func visiblePercent(of itemFrame: CGRect, in viewport: CGRect) -> CGFloat {
        guard itemFrame.width > 0, itemFrame.height > 0, viewport.width > 0, viewport.height > 0 else {
            return 0
        }

        let intersection = itemFrame.intersection(viewport)
        guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else {
            return 0
        }

        let visibleArea = intersection.width * intersection.height
        let totalArea = itemFrame.width * itemFrame.height
        return max(0, min(visibleArea / totalArea, 1))
    }
}
