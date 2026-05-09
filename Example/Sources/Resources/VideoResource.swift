//
//  VideoResource.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import UIKit

// MARK: - VideoItem

/// 视频资源模型
struct VideoItem {
    let title: String
    let url: URL
    let description: String
    let coverColor: UIColor

    /// 生成渐变封面图
    func makeCoverImage(size: CGSize = CGSize(width: 320, height: 180)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let colors = [coverColor.cgColor, coverColor.withAlphaComponent(0.6).cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            } else {
                coverColor.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
            ]
            let titleStr = title as NSString
            let titleSize = titleStr.size(withAttributes: titleAttrs)
            titleStr.draw(
                at: CGPoint(x: 12, y: size.height - titleSize.height - 10),
                withAttributes: titleAttrs
            )
        }
    }
}

// MARK: - VideoResource

/// 视频资源集合
enum VideoResource {
    // MARK: - Apple 官方 HLS 测试流

    static let hlsSamples: [VideoItem] = [
        VideoItem(
            title: "HEVC + Dolby Vision",
            url: makeURL("https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8"),
            description: "Apple 官方 4K HDR 测试流 (HEVC/Dolby Vision/Atmos)",
            coverColor: UIColor(red: 0.15, green: 0.25, blue: 0.50, alpha: 1)
        ),
        VideoItem(
            title: "BipBop (fMP4)",
            url: makeURL("https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"),
            description: "Apple 自适应码率 (fragmented MP4 格式)",
            coverColor: UIColor(red: 0.40, green: 0.20, blue: 0.40, alpha: 1)
        ),
        VideoItem(
            title: "BipBop (TS)",
            url: makeURL("https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"),
            description: "Apple 自适应码率 (MPEG-TS 格式)",
            coverColor: UIColor(red: 0.10, green: 0.40, blue: 0.40, alpha: 1)
        ),
        VideoItem(
            title: "BipBop 16:9",
            url: makeURL("https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"),
            description: "Apple 16:9 宽屏自适应码率",
            coverColor: UIColor(red: 0.30, green: 0.20, blue: 0.10, alpha: 1)
        ),
        VideoItem(
            title: "BipBop (HEVC)",
            url: makeURL("https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8"),
            description: "Apple HEVC 编码自适应码率",
            coverColor: UIColor(red: 0.25, green: 0.15, blue: 0.45, alpha: 1)
        ),
    ]

    // MARK: - 开源/公开 MP4 测试视频

    static let mp4Samples: [VideoItem] = [
        VideoItem(
            title: "Sintel Trailer",
            url: makeURL("https://media.w3.org/2010/05/sintel/trailer.mp4"),
            description: "Blender 开源动画短片 Sintel 预告 (MP4/H.264)",
            coverColor: UIColor(red: 0.50, green: 0.20, blue: 0.20, alpha: 1)
        ),
        VideoItem(
            title: "Big Buck Bunny",
            url: makeURL("https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"),
            description: "Blender 开源动画 Big Buck Bunny (HLS 多码率)",
            coverColor: UIColor(red: 0.20, green: 0.50, blue: 0.20, alpha: 1)
        ),
        VideoItem(
            title: "Tears of Steel",
            url: makeURL("https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"),
            description: "Blender 开源短片 Tears of Steel (HLS)",
            coverColor: UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1)
        ),
    ]

    // MARK: - 短视频 Feed 资源

    static let shortVideoSamples: [VideoItem] = [
        VideoItem(
            title: "Cartier 01",
            url: makeURL("https://raw.githubusercontent.com/sunimp/imgs/master/uPic/cartier_01.mp4"),
            description: "Cartier 短视频素材 01",
            coverColor: UIColor(red: 0.62, green: 0.08, blue: 0.12, alpha: 1)
        ),
        hlsSamples[0],
        mp4Samples[0],
        VideoItem(
            title: "Cartier 02",
            url: makeURL("https://raw.githubusercontent.com/sunimp/imgs/master/uPic/cartier_02.mp4"),
            description: "Cartier 短视频素材 02",
            coverColor: UIColor(red: 0.12, green: 0.10, blue: 0.12, alpha: 1)
        ),
        mp4Samples[1],
        hlsSamples[1],
        VideoItem(
            title: "Cartier 03",
            url: makeURL("https://raw.githubusercontent.com/sunimp/imgs/master/uPic/cartier_03.mp4"),
            description: "Cartier 短视频素材 03",
            coverColor: UIColor(red: 0.52, green: 0.42, blue: 0.30, alpha: 1)
        ),
        mp4Samples[2],
        hlsSamples[2],
        hlsSamples[3],
    ]

    /// 全部测试资源
    static let allSamples: [VideoItem] = hlsSamples + mp4Samples

    private static func makeURL(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            preconditionFailure("无效的视频资源 URL: \(string)")
        }
        return url
    }
}

// MARK: - VideoSampleGroup

/// Demo 可切换的视频素材分组
enum VideoSampleGroup: Int, CaseIterable {
    case hls
    case mp4

    var title: String {
        switch self {
        case .hls: return "HLS"
        case .mp4: return "MP4"
        }
    }

    var samples: [VideoItem] {
        switch self {
        case .hls: return VideoResource.hlsSamples
        case .mp4: return VideoResource.mp4Samples
        }
    }
}
