//
//  GestureEvent.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import CoreGraphics
    import Foundation

    public enum GestureType: Equatable, Hashable, Sendable {
        case unknown
        case singleTap
        case doubleTap
        case pan
        case pinch
        case longPress
    }

    public enum PanDirection: Equatable, Hashable, Sendable {
        case unknown
        case vertical
        case horizontal
    }

    public enum PanLocation: Equatable, Hashable, Sendable {
        case unknown
        case left
        case right
    }

    public enum LongPressPhase: Equatable, Hashable, Sendable {
        case began
        case changed
        case ended
    }

    public enum GestureEvent: Equatable, Sendable {
        case singleTap
        case doubleTap
        case panBegan(direction: PanDirection, location: PanLocation)
        case panChanged(direction: PanDirection, location: PanLocation, velocity: CGPoint)
        case panEnded(direction: PanDirection, location: PanLocation)
        case pinch(scale: CGFloat)
        case longPress(LongPressPhase)
    }
#endif
