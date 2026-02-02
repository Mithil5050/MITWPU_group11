//
//  DocumentPreviewViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 20/01/26.
//

import UIKit
import QuickLook

class DocumentPreviewViewController: UIViewController {

    // MARK: - Public properties (set before presenting)
    var documentURL: URL?

    // MARK: - Private
    private let previewController = QLPreviewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        // Embed QLPreviewController
        previewController.dataSource = self
        previewController.delegate = self

        addChild(previewController)
        view.addSubview(previewController.view)
        previewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            previewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            previewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        previewController.didMove(toParent: self)

        // Navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .label

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareDocument)
        )
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func shareDocument() {
        guard let documentURL = documentURL else { return }

        let activityVC = UIActivityViewController(
            activityItems: [documentURL],
            applicationActivities: nil
        )

        present(activityVC, animated: true)
    }
}

// MARK: - QuickLook DataSource
extension DocumentPreviewViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return documentURL == nil ? 0 : 1
    }

    func previewController(
        _ controller: QLPreviewController,
        previewItemAt index: Int
    ) -> QLPreviewItem {
        return documentURL! as NSURL
    }
}

// MARK: - QuickLook Delegate (optional but future-proof)
extension DocumentPreviewViewController: QLPreviewControllerDelegate {}
