//
//  GroupCodeViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 27/11/25.
//

import UIKit

class GroupCodeViewController: UIViewController {

    @IBOutlet weak var groupCreatedLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!

    // Data passed in
    private var groupName: String = ""
    private var inviteCode: String = ""

    var isFromCreateGroup: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateLabels()
        setCustomBackAsClose()
    }

    // MARK: - Public configure function
        func configure(withGroupName name: String, code: String) {
            self.groupName = name
            self.inviteCode = code

            if isViewLoaded {
                updateLabels()
            }
        }

        // MARK: - UI Setup
        private func setupUI() {
            // Make buttons round
            copyButton.layer.cornerRadius = copyButton.bounds.height / 2
            copyButton.clipsToBounds = true

            shareButton.layer.cornerRadius = shareButton.bounds.height / 2
            shareButton.clipsToBounds = true
        }
    
    private func setCustomBackAsClose() {
        let closeItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWholeFlow))
        navigationItem.leftBarButtonItem = closeItem
    }

        // MARK: - Update UI text
        private func updateLabels() {
            
            if isFromCreateGroup {
                groupCreatedLabel.text = "Group \"\(groupName)\" Created"
            } else {
                groupCreatedLabel.text = "Code for \(groupName)"
            }

            codeLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .semibold)
            codeLabel.text = inviteCode
        }

    // MARK: - Button Actions
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        guard !inviteCode.isEmpty else { return }

            // Copy to clipboard
            UIPasteboard.general.string = inviteCode

            // Save original image (or use a sensible fallback)
            let fallback = UIImage(systemName: "doc.on.doc")?.withRenderingMode(.alwaysTemplate)
            let originalImage = sender.image(for: .normal) ?? fallback

            // Success image
            let checkmarkImage = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)

            // Make sure tint is applied
            sender.tintColor = .white
            sender.imageView?.contentMode = .scaleAspectFit

            // Animate to checkmark
            DispatchQueue.main.async {
                UIView.transition(with: sender,
                                  duration: 0.18,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                      sender.setImage(checkmarkImage, for: .normal)
                                      // optional: change background briefly for stronger feedback
                                      // sender.backgroundColor = UIColor.systemGreen
                                  }, completion: { _ in
                                      // Revert after delay
                                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                          UIView.transition(with: sender,
                                                            duration: 0.18,
                                                            options: .transitionCrossDissolve,
                                                            animations: {
                                                                sender.setImage(originalImage, for: .normal)
                                                                // revert background if you changed it
                                                                // sender.backgroundColor = yourOriginalColor
                                                            }, completion: nil)
                                      }
                                  })
            }
    }

    @IBAction func shareButtonTapped(_ sender: UIButton) {
        let shareText = "Join my group \"\(groupName)\" with invite code: \(inviteCode)"
                let ac = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

                ac.popoverPresentationController?.sourceView = sender
                ac.popoverPresentationController?.sourceRect = sender.bounds

                present(ac, animated: true)
    }
    
    @objc private func closeWholeFlow() {
        // This dismisses the entire modal navigation controller
        dismiss(animated: true)
    }
}
