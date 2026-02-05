//
//  CreateFolderViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 27/11/25.
//

import UIKit

class CreateFolderViewController: UIViewController {
    
    @IBOutlet var folderNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFieldStyling(folderNameTextField, placeholder: "Enter Folder Name...")
    }
    private func setupFieldStyling(_ textField: UITextField, placeholder: String) {
            // Match Flashcard Box Styling
            textField.backgroundColor = .secondarySystemGroupedBackground
            textField.textColor = .label
            textField.borderStyle = .none
            textField.layer.cornerRadius = 12
            textField.font = UIFont.preferredFont(forTextStyle: .body)
            
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.placeholderText]
            )
            
            // Exact Padding Match (16pt)
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
            textField.leftView = paddingView
            textField.leftViewMode = .always
            
            // Exact Height Match (54pt)
            textField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textField.heightAnchor.constraint(equalToConstant: 54)
            ])
        }
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        guard let newFolderName = folderNameTextField.text, !newFolderName.isEmpty else {
            
            print("Folder name cannot be empty.")
            return
        }
        
        
        DataManager.shared.createNewSubjectFolder(name: newFolderName)
        
        self.dismiss(animated: true, completion: nil)
    }
}
