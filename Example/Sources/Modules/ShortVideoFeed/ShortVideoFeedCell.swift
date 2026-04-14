//
//  ShortVideoFeedCell.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import UIKit

// MARK: - ShortVideoFeedCell

/// 全屏视频 Cell（抖音风格）
final class ShortVideoFeedCell: UICollectionViewCell {
    static let reuseIdentifier = "ShortVideoFeedCell"

    // MARK: - 子视图

    /// 视频容器（tag = 300，供 Player 通过 tag 查找）
    let videoContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.tag = 300
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 底部信息栏（半透明渐变背景）
    let infoView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 标题
    let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .white
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    /// 描述
    let descLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .white
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    /// 点赞按钮
    let likeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    /// 评论按钮
    let commentButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "bubble.right.fill"), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    /// 分享按钮
    let shareButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "arrowshape.turn.up.right.fill"), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    /// 渐变图层
    private let gradientLayer = CAGradientLayer()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 布局

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = infoView.bounds
    }

    // MARK: - 配置

    func configure(title: String, description: String) {
        titleLabel.text = title
        descLabel.text = description
    }

    // MARK: - 私有方法

    private func setupViews() {
        contentView.backgroundColor = .black

        // 视频容器铺满
        contentView.addSubview(videoContainerView)

        // 底部信息栏
        contentView.addSubview(infoView)
        setupGradient()
        infoView.addSubview(titleLabel)
        infoView.addSubview(descLabel)

        // 右侧互动按钮
        contentView.addSubview(likeButton)
        contentView.addSubview(commentButton)
        contentView.addSubview(shareButton)

        NSLayoutConstraint.activate([
            // 视频容器铺满整个 cell
            videoContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // 底部信息栏
            infoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            infoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            infoView.heightAnchor.constraint(equalToConstant: 120),

            // 标题
            titleLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -60),
            titleLabel.bottomAnchor.constraint(equalTo: descLabel.topAnchor, constant: -6),

            // 描述
            descLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -60),
            descLabel.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -16),

            // 右侧按钮（垂直排列，距底部 160pt）
            shareButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            shareButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -160),
            shareButton.widthAnchor.constraint(equalToConstant: 44),
            shareButton.heightAnchor.constraint(equalToConstant: 44),

            commentButton.trailingAnchor.constraint(equalTo: shareButton.trailingAnchor),
            commentButton.bottomAnchor.constraint(equalTo: shareButton.topAnchor, constant: -16),
            commentButton.widthAnchor.constraint(equalToConstant: 44),
            commentButton.heightAnchor.constraint(equalToConstant: 44),

            likeButton.trailingAnchor.constraint(equalTo: shareButton.trailingAnchor),
            likeButton.bottomAnchor.constraint(equalTo: commentButton.topAnchor, constant: -16),
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            likeButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor(white: 0, alpha: 0.6).cgColor,
        ]
        gradientLayer.locations = [0, 1]
        infoView.layer.insertSublayer(gradientLayer, at: 0)
    }
}
