//
//  Utilities.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Foundation
import os
#if canImport(UIKit)
    import UIKit
#endif

// MARK: - 时间格式化

/// 将秒数格式化为时间字符串
public enum TimeFormatter: Sendable {
    /// 将秒数格式化为 "mm:ss" 或 "HH:mm:ss"
    public static func string(from seconds: Int) -> String {
        guard seconds > 0 else { return "00:00" }
        if seconds < 3600 {
            return String(format: "%02d:%02d", seconds / 60, seconds % 60)
        } else {
            return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
        }
    }
}

// MARK: - 图片生成

#if canImport(UIKit)
    /// 纯色图片生成工具
    public enum ImageGenerator: Sendable {
        /// 生成指定颜色和尺寸的纯色图片
        @MainActor
        public static func image(color: UIColor, size: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }
    }
#endif

// MARK: - 日志

/// AlloyPlayer 统一日志
public let alloyLogger = Logger(subsystem: "com.alloyplayer", category: "AlloyPlayer")
