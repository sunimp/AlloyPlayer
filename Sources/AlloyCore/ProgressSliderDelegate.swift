//
//  ProgressSliderDelegate.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    /// 进度滑块代理协议
    @MainActor
    public protocol ProgressSliderDelegate: AnyObject {
        /// 开始触摸滑块
        func sliderTouchBegan(_ slider: UIView, value: Float)

        /// 滑块值变化中
        func sliderValueChanged(_ slider: UIView, value: Float)

        /// 触摸滑块结束
        func sliderTouchEnded(_ slider: UIView, value: Float)

        /// 点击了滑块轨道
        func sliderTapped(_ slider: UIView, value: Float)
    }

    // MARK: - 默认空实现

    public extension ProgressSliderDelegate {
        func sliderTouchBegan(_: UIView, value _: Float) {}
        func sliderValueChanged(_: UIView, value _: Float) {}
        func sliderTouchEnded(_: UIView, value _: Float) {}
        func sliderTapped(_: UIView, value _: Float) {}
    }
#endif
