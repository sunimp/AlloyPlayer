//
//  ScalingMode.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/13.
//

/// 视频缩放模式。
public enum ScalingMode: Equatable, Sendable {
    /// 等比例完整显示，可能留空边。
    case aspectFit

    /// 等比例填充显示，可能裁剪边缘。
    case aspectFill

    /// 拉伸填满显示区域。
    case fill
}
