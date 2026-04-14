//
//  RenderView.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    /// 播放器渲染视图容器
    ///
    /// 承载播放引擎的渲染层（如 AVPlayerLayer），并提供封面图视图。
    /// 通过 `scalingMode` 控制视频缩放方式。
    @MainActor
    public class RenderView: UIView {
        // MARK: - 子视图

        /// 播放引擎的实际渲染视图（由引擎设置）
        public var playerView: UIView? {
            didSet {
                oldValue?.removeFromSuperview()
                if let playerView {
                    insertSubview(playerView, at: 0)
                    playerView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        playerView.topAnchor.constraint(equalTo: topAnchor),
                        playerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                        playerView.trailingAnchor.constraint(equalTo: trailingAnchor),
                        playerView.bottomAnchor.constraint(equalTo: bottomAnchor),
                    ])
                }
            }
        }

        /// 封面图视图
        public private(set) lazy var coverImageView: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.translatesAutoresizingMaskIntoConstraints = false
            addSubview(iv)
            NSLayoutConstraint.activate([
                iv.topAnchor.constraint(equalTo: topAnchor),
                iv.leadingAnchor.constraint(equalTo: leadingAnchor),
                iv.trailingAnchor.constraint(equalTo: trailingAnchor),
                iv.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
            return iv
        }()

        // MARK: - 属性

        /// 视频缩放模式
        public var scalingMode: ScalingMode = .aspectFit

        /// 视频原始尺寸
        public var presentationSize: CGSize = .zero

        /// 布局变化回调（内部使用）
        public var layoutSubviewsCallback: (() -> Void)?

        // MARK: - 初始化

        override public init(frame: CGRect) {
            super.init(frame: frame)
            clipsToBounds = true
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - 布局

        override public func layoutSubviews() {
            super.layoutSubviews()
            layoutSubviewsCallback?()
        }
    }
#endif
