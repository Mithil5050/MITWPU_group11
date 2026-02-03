//
//  AddFlashcardsViewController.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 09/01/26.
//

import UIKit

class AddFlashcardsViewController: UIViewController {
    weak var delegate : AddFlashcardsDelegate?
    
    @IBOutlet weak var termsTextField: UITextField!
    
    @IBOutlet weak var definitionsTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Flashcard"
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        self.navigationItem.leftBarButtonItem = closeButton
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        
        setupFieldStyling(termsTextField, placeholder: "Enter term...")
        setupFieldStyling(definitionsTextField, placeholder: "Enter definition...")
        
        view.backgroundColor = .systemGroupedBackground
    }

    private func setupFieldStyling(_ textField: UITextField, placeholder: String) {
        textField.backgroundColor = .secondarySystemGroupedBackground
        textField.textColor = .label
        textField.borderStyle = .none
        textField.layer.cornerRadius = 10
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
        )
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    @objc private func closeTapped() {
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Save Action
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let term = termsTextField.text, !term.isEmpty,
              let definition = definitionsTextField.text, !definition.isEmpty else {
            print("Error: Both fields must be filled.")
            return
        }
        
        let newCard = Flashcard(term: term, definition: definition)
        
        delegate?.didCreateNewFlashcard(card: newCard)
        
        dismiss(animated: true, completion: nil)
    }

    

}
