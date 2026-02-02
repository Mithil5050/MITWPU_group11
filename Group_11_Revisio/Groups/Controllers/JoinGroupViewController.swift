//
//  JoinGroupViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 27/11/25.
//

import UIKit

class JoinGroupViewController: UIViewController {
    
    private let fakeJoinedGroupName = "Joined Group"
    weak var delegate: JoinGroupDelegate?

    @IBOutlet weak var codeTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If this VC was pushed onto a navigation stack (not root), do nothing:
        // the system will show the Back button automatically.
        if let nav = navigationController, nav.viewControllers.count > 1 {
            // Remove any leftBarButtonItem created in storyboard (avoid duplicates)
            navigationItem.leftBarButtonItem = nil
        } else {

            if navigationItem.leftBarButtonItem == nil {
                let close = UIBarButtonItem(barButtonSystemItem: .close,
                                            target: self,
                                            action: #selector(closeButtonTapped(_:)))
                navigationItem.leftBarButtonItem = close
            }
        }
    }
    
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        
        let enteredCode = codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            // FRONTEND DEMO LOGIC:
            // Any code → open existing iMAAC group
            let joinedGroupName = "iMAAC"

            dismiss(animated: true) {
                self.delegate?.didJoinGroup(groupName: joinedGroupName)
            }

        }
    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

}
