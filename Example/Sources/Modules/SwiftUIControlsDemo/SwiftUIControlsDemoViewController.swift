//
//  SwiftUIControlsDemoViewController.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/5/9.
//

import SwiftUI
import UIKit

// MARK: - SwiftUIControlsDemoViewController

/// SwiftUI 控制层演示容器
final class SwiftUIControlsDemoViewController: UIViewController {
    private var hostingController: UIHostingController<SwiftUIControlsDemoView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupHostingController()
    }

    private func setupHostingController() {
        let hostingController = UIHostingController(rootView: SwiftUIControlsDemoView())
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController
    }
}
