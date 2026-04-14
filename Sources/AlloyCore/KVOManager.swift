//
//  KVOManager.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Foundation

/// 安全的 KVO 管理器
///
/// 基于 Swift 强类型 KeyPath API，自动在 deinit 时移除所有观察。
@MainActor
public final class KVOManager {
    private var observations: [NSKeyValueObservation] = []

    public init() {}

    /// 添加 KVO 观察
    /// - Parameters:
    ///   - object: 被观察对象
    ///   - keyPath: 观察的 KeyPath
    ///   - options: 观察选项
    ///   - handler: 变化回调
    public func observe<Object: NSObject, Value>(
        _ object: Object,
        keyPath: KeyPath<Object, Value>,
        options: NSKeyValueObservingOptions = [.new],
        handler: @escaping (Object, NSKeyValueObservedChange<Value>) -> Void
    ) {
        let observation = object.observe(keyPath, options: options, changeHandler: handler)
        observations.append(observation)
    }

    /// 移除所有观察
    public func invalidate() {
        observations.forEach { $0.invalidate() }
        observations.removeAll()
    }

    deinit {
        observations.forEach { $0.invalidate() }
    }
}
