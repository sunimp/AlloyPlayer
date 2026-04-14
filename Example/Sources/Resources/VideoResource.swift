//
//  VideoResource.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import Foundation

// MARK: - VideoItem

/// 视频资源模型
struct VideoItem {
    let title: String
    let url: URL
    let description: String
}

// MARK: - VideoResource

/// 视频资源集合
enum VideoResource {
    /// HLS 测试流
    static let hlsSamples: [VideoItem] = [
        VideoItem(
            title: "HEVC + Dolby Vision",
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8")!,
            description: "Apple 官方 4K HDR 测试流"
        ),
        VideoItem(
            title: "BipBop (fMP4)",
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!,
            description: "Apple 官方自适应码率测试流"
        ),
        VideoItem(
            title: "BipBop (TS)",
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!,
            description: "Apple 官方 MPEG-TS 格式测试流"
        ),
        VideoItem(
            title: "BipBop 16:9",
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!,
            description: "16:9 宽屏自适应码率"
        ),
    ]

    /// MP4/其他测试流
    static let mp4Samples: [VideoItem] = [
        VideoItem(
            title: "Sintel Trailer",
            url: URL(string: "https://media.w3.org/2010/05/sintel/trailer.mp4")!,
            description: "开源动画短片预告"
        ),
        VideoItem(
            title: "Big Buck Bunny",
            url: URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!,
            description: "经典开源动画测试流"
        ),
    ]

    /// 全部测试资源
    static let allSamples: [VideoItem] = hlsSamples + mp4Samples
}
