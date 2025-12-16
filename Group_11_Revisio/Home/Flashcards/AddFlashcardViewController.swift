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
        // Optional: Set modal presentation style for modern look (or set in Storyboard)
        if #available(iOS 13.0, *) {
            isModalInPresentation = true // Prevent accidental swipe-down dismissal
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        // Dismiss the modal screen
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Save Action
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let term = termTextField.text, !term.isEmpty,
              let definition = definitionTextField.text, !definition.isEmpty else {
            // Provide user feedback (e.g., alert or shake animation)
            print("Error: Both fields must be filled.")
            return
        }
        
        let newCard = Flashcard(term: term, definition: definition)
        
        // 💥 KEY STEP: Call the delegate method to pass data back
        delegate?.didCreateNewFlashcard(card: newCard)
        
        // Dismiss the screen after successful data transfer
        dismiss(animated: true, completion: nil)
    }
}
