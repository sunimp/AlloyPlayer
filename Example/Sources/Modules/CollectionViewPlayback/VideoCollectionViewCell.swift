//
//  VideoCollectionViewCell.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import UIKit

// MARK: - VideoCollectionViewCell

/// 视频 CollectionView Cell
final class VideoCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoCollectionViewCell"

    /// 视频容器 (tag = 200，供 Player 通过 tag 查找)
    let videoContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.tag = 200
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 封面图
    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(white: 1, alpha: 0.7)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.backgroundColor = .darkGray
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        contentView.addSubview(videoContainerView)
        videoContainerView.addSubview(coverImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descLabel)

        NSLayoutConstraint.activate([
            videoContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoContainerView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.7),

            coverImageView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
        ])
    }

    // MARK: - 配置

    private var currentVideo: VideoItem?

    func configure(with video: VideoItem) {
        titleLabel.text = video.title
        descLabel.text = video.description
        currentVideo = video
        // 延迟到布局完成后按实际尺寸生成封面
        coverImageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if coverImageView.image == nil, let video = currentVideo {
            let containerSize = videoContainerView.bounds.size
            if containerSize.width > 0, containerSize.height > 0 {
                coverImageView.image = video.makeCoverImage(size: containerSize)
            }
        }
    }
}
