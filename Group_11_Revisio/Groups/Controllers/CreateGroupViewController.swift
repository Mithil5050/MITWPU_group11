//
//  CreateGroupViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 27/11/25.
//

import UIKit

class CreateGroupViewController: UIViewController {
    
    weak var delegate: CreateGroupDelegate?
    
    @IBOutlet weak var groupNameTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func generateButtonTapped(_ sender: UIButton) {
        let nameText = groupNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let groupName = nameText.isEmpty ? "New Group" : nameText
        let code = CreateGroupViewController.generateInviteCode()

        let storyboard = UIStoryboard(name: "Groups", bundle: nil)
        guard let codeVC = storyboard.instantiateViewController(withIdentifier: "GroupCodeVC") as? GroupCodeViewController else { return }
        codeVC.configure(withGroupName: groupName, code: code)

        Task {
            do {
                let newGroup = try await SupabaseManager.shared.createGroup(
                    name: groupName,
                    avatarName: "gpfp10",
                    inviteCode: code
                )
                delegate?.didCreateGroup(newGroup)
            } catch {
                print("❌ Failed to create group: \(error)")
            }
        }

        if let nav = self.navigationController {
            nav.pushViewController(codeVC, animated: true)
        }
    }

    @IBAction func closeButtonTapped(_ sender: UIButton) {
        // If this view controller was presented modally (direct or inside a nav controller)
            if let presenting = self.presentingViewController {
                // If this VC is inside a navigation controller that was presented modally,
                // dismiss the whole nav stack.
                if let nav = self.navigationController, nav.presentingViewController != nil {
                    nav.dismiss(animated: true, completion: nil)
                } else {
                    // Otherwise dismiss this view controller
                    presenting.dismiss(animated: true, completion: nil)
                }
                return
            }

            // If it was pushed onto a navigation stack (not modal), pop it
            if let nav = self.navigationController {
                nav.popViewController(animated: true)
                return
            }

            // Fallback — try dismiss
            self.dismiss(animated: true, completion: nil)
    }

    static func generateInviteCode() -> String {
            let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
            func randomBlock() -> String {
                return String((0..<4).map { _ in chars.randomElement()! })
            }
            return "\(randomBlock())-\(randomBlock())"
        }
}
