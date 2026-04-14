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

    /// 点击回调
    var onTap: (() -> Void)?

    // MARK: - 子视图

    /// 视频容器（tag = 300）
    let videoContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.tag = 300
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 封面占位
    private let coverView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 底部信息栏
    private let infoView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = UIColor(white: 1, alpha: 0.8)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    /// 底部进度条（极细）
    private let progressBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.3)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let progressFill: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    /// 暂停指示器
    private let pauseIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: config))
        iv.tintColor = UIColor(white: 1, alpha: 0.8)
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 右侧互动按钮
    private let likeButton = ShortVideoFeedCell.makeButton(systemName: "heart.fill", label: "喜欢")
    private let commentButton = ShortVideoFeedCell.makeButton(systemName: "bubble.right.fill", label: "评论")
    private let shareButton = ShortVideoFeedCell.makeButton(systemName: "arrowshape.turn.up.right.fill", label: "分享")

    private let gradientLayer = CAGradientLayer()
    private var progressFillWidth: NSLayoutConstraint?

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupTapGesture()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = infoView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        progressFillWidth?.constant = 0
        pauseIcon.isHidden = true
        coverView.isHidden = false
        onTap = nil
    }

    // MARK: - 公开方法

    func configure(title: String, description: String, coverColor: UIColor) {
        titleLabel.text = "@\(title)"
        descLabel.text = description
        coverView.backgroundColor = coverColor
    }

    /// 隐藏封面（开始播放时调用）
    func hideCover() {
        coverView.isHidden = true
    }

    /// 更新播放进度（0...1）
    func updateProgress(_ value: Float) {
        let width = contentView.bounds.width * CGFloat(max(0, min(value, 1)))
        progressFillWidth?.constant = width
    }

    /// 显示暂停指示器（短暂动画）
    func showPauseIndicator() {
        pauseIcon.isHidden = false
        pauseIcon.alpha = 1
        pauseIcon.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.15, animations: {
            self.pauseIcon.transform = .identity
        }, completion: { _ in
            UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
                self.pauseIcon.alpha = 0
            }, completion: { _ in
                self.pauseIcon.isHidden = true
            })
        })
    }

    // MARK: - 私有方法

    private func setupViews() {
        contentView.backgroundColor = .black

        contentView.addSubview(videoContainerView)
        contentView.addSubview(coverView)
        contentView.addSubview(infoView)
        contentView.addSubview(pauseIcon)

        // 渐变
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor(white: 0, alpha: 0.5).cgColor]
        infoView.layer.insertSublayer(gradientLayer, at: 0)

        // 进度条放在 infoView 内部，titleLabel 上方
        infoView.addSubview(progressBar)
        progressBar.addSubview(progressFill)
        infoView.addSubview(titleLabel)
        infoView.addSubview(descLabel)

        // 右侧按钮（间距收紧）
        let buttonStack = UIStackView(arrangedSubviews: [likeButton, commentButton, shareButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 16
        buttonStack.alignment = .center
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStack)

        // 进度条填充
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        let fillWidth = progressFill.widthAnchor.constraint(equalToConstant: 0)
        progressFillWidth = fillWidth

        NSLayoutConstraint.activate([
            videoContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            coverView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // infoView 锚定到底部
            infoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            infoView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            infoView.heightAnchor.constraint(equalToConstant: 130),

            // 进度条在 infoView 内顶部
            progressBar.topAnchor.constraint(equalTo: infoView.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            progressBar.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            progressBar.heightAnchor.constraint(equalToConstant: 2),

            progressFill.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressBar.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressBar.bottomAnchor),
            fillWidth,

            // titleLabel 在进度条下方
            titleLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: buttonStack.leadingAnchor, constant: -8),

            // descLabel 在 titleLabel 下方
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            descLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: buttonStack.leadingAnchor, constant: -8),

            // 右侧按钮紧贴右边
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            buttonStack.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -8),

            pauseIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pauseIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        onTap?()
    }

    private static func makeButton(systemName: String, label: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 28)
        let btn = UIImageView(image: UIImage(systemName: systemName, withConfiguration: config))
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .systemFont(ofSize: 11)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(btn)
        container.addSubview(lbl)

        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: container.topAnchor),
            btn.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            lbl.topAnchor.constraint(equalTo: btn.bottomAnchor, constant: 2),
            lbl.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            lbl.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: 50),
        ])

        return container
    }
}
