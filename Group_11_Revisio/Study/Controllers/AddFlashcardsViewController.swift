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
    
    
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
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
        
      
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
        guard let term = termsTextField.text, !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Error: Term must be filled.")
            return
        }
        
        let manualDefinition = definitionsTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
       
        if manualDefinition.isEmpty {
            
            sender.isEnabled = false
            sender.setTitle("Generating...", for: .normal)
            loadingIndicator.startAnimating()
            view.isUserInteractionEnabled = false
            
            Task {
               
                let prompt = "Provide a short, concise, and accurate definition for the flashcard term: '\(term)'. Return ONLY the definition text without any quotes, markdown, or extra conversational text."
                
                do {
                    let aiDefinition = try await AIContentManager.shared.generateContent(
                        topic: prompt,
                        type: "Definition",
                        count: 1,
                        difficulty: "Medium"
                    )
                    
                    DispatchQueue.main.async {
                        self.loadingIndicator.stopAnimating()
                        
                       
                        let cleanDef = aiDefinition.trimmingCharacters(in: .whitespacesAndNewlines)
                        let newCard = Flashcard(term: term, definition: cleanDef)
                        
                       
                        self.delegate?.didCreateNewFlashcard(card: newCard)
                        self.dismiss(animated: true, completion: nil)
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        self.loadingIndicator.stopAnimating()
                        self.view.isUserInteractionEnabled = true
                        sender.isEnabled = true
                        sender.setTitle("Save", for: .normal)
                        
                        
                        let alert = UIAlertController(title: "AI Error", message: "Failed to generate a definition. Please type it manually.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        } else {
           
            let newCard = Flashcard(term: term, definition: manualDefinition)
            delegate?.didCreateNewFlashcard(card: newCard)
            dismiss(animated: true, completion: nil)
        }
    }
}
