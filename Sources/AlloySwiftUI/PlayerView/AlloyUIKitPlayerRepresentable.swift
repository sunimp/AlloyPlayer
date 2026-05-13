//
//  AlloyUIKitPlayerRepresentable.swift
//  AlloySwiftUI
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyCore
    import AlloyUIKit
    import SwiftUI
    import UIKit

    struct AlloyUIKitPlayerRepresentable<Controls: View>: UIViewRepresentable {
        let controller: AlloyPlayerController
        let controls: (AlloyPlayerController) -> Controls

        func makeUIView(context _: Context) -> AlloyUIKit.AlloyPlayerView {
            let playerView = AlloyUIKit.AlloyPlayerView(session: controller.session)
            playerView.backgroundColor = .black
            playerView.controlOverlay = SwiftUIHostingControlOverlay(controller: controller, controls: controls)
            return playerView
        }

        func updateUIView(_ uiView: AlloyUIKit.AlloyPlayerView, context _: Context) {
            uiView.controlOverlay?.render(state: controller.state)
        }
    }

    private final class SwiftUIHostingControlOverlay<Content: View>: UIView, UIKitControlOverlay {
        var actionHandler: ((PlaybackControlAction) -> Void)?

        private let controller: AlloyPlayerController
        private let hostingController: UIHostingController<Content>

        init(
            controller: AlloyPlayerController,
            @ViewBuilder controls: @escaping (AlloyPlayerController) -> Content
        ) {
            self.controller = controller
            hostingController = UIHostingController(rootView: controls(controller))
            super.init(frame: .zero)
            backgroundColor = .clear
            hostingController.view.backgroundColor = .clear
            installHostedView()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func render(state _: PlaybackStateSnapshot) {}
        func handle(event _: PlaybackEvent) {}

        private func installHostedView() {
            let hostedView = hostingController.view!
            hostedView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(hostedView)
            NSLayoutConstraint.activate([
                hostedView.topAnchor.constraint(equalTo: topAnchor),
                hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
                hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
                hostedView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
    }
#endif
