@testable import AlloyAVPlayer
import Combine
import Testing

#if canImport(UIKit)
    import XCTest
#endif

@Test func moduleImports() {
    // 验证模块可正常导入
}

#if canImport(UIKit)
    @MainActor
    final class AVPlayerManagerTests: XCTestCase {
        func testReloadPlayerPreparesSameURLAgain() {
            let manager = AVPlayerManager()
            guard let url = URL(string: "https://example.invalid/video.mp4") else {
                XCTFail("测试 URL 构造失败")
                return
            }
            var prepareCount = 0
            var cancellables = Set<AnyCancellable>()

            manager.prepareToPlayPublisher
                .sink { _ in prepareCount += 1 }
                .store(in: &cancellables)

            manager.assetURL = url
            manager.reloadPlayer()

            XCTAssertEqual(prepareCount, 2)
        }
    }
#endif
