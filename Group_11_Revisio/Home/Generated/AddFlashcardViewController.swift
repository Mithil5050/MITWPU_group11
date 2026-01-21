import UIKit

class AddFlashcardViewController: UIViewController {

    weak var delegate: AddFlashcardDelegate?
    
    @IBOutlet weak var termTextField: UITextField!
    @IBOutlet weak var definitionTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let term = termTextField.text, !term.isEmpty,
              let definition = definitionTextField.text, !definition.isEmpty else {
            return
        }
        
        let newCard = Flashcard(term: term, definition: definition)
        delegate?.didCreateNewFlashcard(card: newCard)
        dismiss(animated: true)
    }
}
