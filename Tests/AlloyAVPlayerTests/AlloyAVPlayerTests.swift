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
            let url = URL(string: "https://example.invalid/video.mp4")!
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
