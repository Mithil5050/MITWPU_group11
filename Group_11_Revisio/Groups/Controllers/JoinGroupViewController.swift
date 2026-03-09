//
//  JoinGroupViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 27/11/25.
//

import UIKit

class JoinGroupViewController: UIViewController {

    weak var delegate: JoinGroupDelegate?

    @IBOutlet weak var codeTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let nav = navigationController, nav.viewControllers.count > 1 {
            navigationItem.leftBarButtonItem = nil
        } else {
            if navigationItem.leftBarButtonItem == nil {
                let close = UIBarButtonItem(
                    barButtonSystemItem: .close,
                    target: self,
                    action: #selector(closeButtonTapped(_:))
                )
                navigationItem.leftBarButtonItem = close
            }
        }
    }

    @IBAction func joinButtonTapped(_ sender: UIButton) {
        let enteredCode = codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !enteredCode.isEmpty else { return }

        Task {
            do {
                let joined = try await SupabaseManager.shared.joinGroup(code: enteredCode)
                await MainActor.run {
                    dismiss(animated: true) {
                        self.delegate?.didJoinGroup(joined)
                    }
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Invalid Code",
                        message: "No group found with that invite code.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}
