//
//  GestureConfiguration.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    /// 手势配置。
    public struct GestureConfiguration: Equatable, Sendable {
        /// 禁用的手势类型集合。
        public var disabledTypes: Set<GestureType>

        /// 禁用的拖动方向集合。
        public var disabledPanDirections: Set<PanDirection>

        /// 创建手势配置。
        public init(
            disabledTypes: Set<GestureType> = [],
            disabledPanDirections: Set<PanDirection> = []
        ) {
            self.disabledTypes = disabledTypes
            self.disabledPanDirections = disabledPanDirections
        }
    }
#endif
