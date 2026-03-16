//
//  CreateGroupViewController.swift
//  Group_11_Revisio
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
        guard let codeVC = storyboard.instantiateViewController(
            withIdentifier: "GroupCodeVC") as? GroupCodeViewController else { return }
        codeVC.configure(withGroupName: groupName, code: code)

        Task {
            do {
                // No avatar on creation — defaults to person.3.fill placeholder
                let newGroup = try await SupabaseManager.shared.createGroup(
                    name: groupName,
                    inviteCode: code
                )
                await MainActor.run {
                    delegate?.didCreateGroup(newGroup)
                }
            } catch {
                print("Failed to create group: \(error)")
            }
        }

        if let nav = self.navigationController {
            nav.pushViewController(codeVC, animated: true)
        }
    }

    @IBAction func closeButtonTapped(_ sender: UIButton) {
        if let presenting = self.presentingViewController {
            if let nav = self.navigationController, nav.presentingViewController != nil {
                nav.dismiss(animated: true)
            } else {
                presenting.dismiss(animated: true)
            }
            return
        }
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
            return
        }
        self.dismiss(animated: true)
    }

    static func generateInviteCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        func randomBlock() -> String {
            return String((0..<4).map { _ in chars.randomElement()! })
        }
        return "\(randomBlock())-\(randomBlock())"
    }
}
