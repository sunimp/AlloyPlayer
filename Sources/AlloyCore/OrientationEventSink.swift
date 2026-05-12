//
//  OrientationEventSink.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/12.
//

#if canImport(UIKit)
    import Foundation

    /// 横竖屏与锁定事件接收者。
    @MainActor
    public protocol OrientationEventSink: AnyObject {
        func player(_ player: Player, didChangeLockState isLocked: Bool)
        func player(_ player: Player, willChangeOrientation observer: OrientationManager)
        func player(_ player: Player, didChangeOrientation observer: OrientationManager)
    }

    public extension OrientationEventSink {
        func player(_: Player, didChangeLockState _: Bool) {}
        func player(_: Player, willChangeOrientation _: OrientationManager) {}
        func player(_: Player, didChangeOrientation _: OrientationManager) {}
    }
#endif
