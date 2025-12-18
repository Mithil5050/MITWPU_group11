//
//  AddFlashcardDelegate.swift
//  Group_11_Revisio
//
//  Created by Mithil on 16/12/25.
//


import UIKit

class AddFlashcardViewController: UIViewController {

    // MARK: - Delegate and Outlets
    weak var delegate: AddFlashcardDelegate?
    
    // Connect these in Storyboard!
    @IBOutlet weak var termTextField: UITextField!
    @IBOutlet weak var definitionTextField: UITextField!
    
    // MARK: - Lifecycle & Dismissal
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        self.navigationItem.leftBarButtonItem = closeButton
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
    }
    
    @objc private func closeTapped() {
        // Mirrors cancel behavior; dismiss the modal add screen
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Save Action
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let term = termTextField.text, !term.isEmpty,
              let definition = definitionTextField.text, !definition.isEmpty else {
            print("Error: Both fields must be filled.")
            return
        }
        
        let newCard = Flashcard(term: term, definition: definition)
        
        delegate?.didCreateNewFlashcard(card: newCard)
        
        dismiss(animated: true, completion: nil)
    }
}
