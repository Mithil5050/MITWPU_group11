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

        // Do any additional setup after loading the view.
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
        guard let term = termsTextField.text, !term.isEmpty,
              let definition = definitionsTextField.text, !definition.isEmpty else {
            print("Error: Both fields must be filled.")
            return
        }
        
        let newCard = Flashcard(term: term, definition: definition)
        
        delegate?.didCreateNewFlashcard(card: newCard)
        
        dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
