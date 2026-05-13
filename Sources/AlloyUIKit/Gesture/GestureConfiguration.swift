//
//  GestureConfiguration.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    /// 手势配置。
    public struct GestureConfiguration: Equatable, Sendable {
        public var disabledTypes: Set<GestureType>
        public var disabledPanDirections: Set<PanDirection>

        public init(
            disabledTypes: Set<GestureType> = [],
            disabledPanDirections: Set<PanDirection> = []
        ) {
            self.disabledTypes = disabledTypes
            self.disabledPanDirections = disabledPanDirections
        }
    }
#endif
