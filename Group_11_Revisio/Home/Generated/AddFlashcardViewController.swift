import UIKit

class AddFlashcardViewController: UIViewController {

    weak var delegate: AddFlashcardDelegate?
    
    @IBOutlet weak var termTextField: UITextField!
    @IBOutlet weak var definitionTextField: UITextField!
    
    // An activity indicator to show the user that the AI is thinking
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        termTextField.layer.cornerRadius = 15
        definitionTextField.layer.cornerRadius = 15
        
        // Setup Loading Indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let term = termTextField.text, !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // If the term is completely empty, do nothing
            return
        }
        
        let manualDefinition = definitionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // ✅ IF DEFINITION IS EMPTY -> USE AI TO GENERATE IT
        if manualDefinition.isEmpty {
            
            sender.isEnabled = false
            sender.setTitle("Generating...", for: .normal)
            loadingIndicator.startAnimating()
            view.isUserInteractionEnabled = false // Prevent extra taps
            
            Task {
                // Instruct the AI to just give us a clean definition
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
                        
                        // Clean the output and create the card
                        let cleanDef = aiDefinition.trimmingCharacters(in: .whitespacesAndNewlines)
                        let newCard = Flashcard(term: term, definition: cleanDef, keyword: term)
                        
                        // Pass back to the deck and dismiss
                        self.delegate?.didCreateNewFlashcard(card: newCard)
                        self.dismiss(animated: true)
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        self.loadingIndicator.stopAnimating()
                        self.view.isUserInteractionEnabled = true
                        sender.isEnabled = true
                        sender.setTitle("Save", for: .normal)
                        
                        // Show error so the user knows they need to type it manually
                        let alert = UIAlertController(title: "AI Error", message: "Failed to generate a definition. Please type it manually.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        } else {
            let newCard = Flashcard(term: term, definition: manualDefinition, keyword: term)
            delegate?.didCreateNewFlashcard(card: newCard)
            dismiss(animated: true)
        }
    }
}
