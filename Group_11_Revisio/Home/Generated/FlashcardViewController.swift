import UIKit
import Foundation

// MARK: - 1. Flashcard Data Structure
struct Flashcard {
    let term: String
    let definition: String
}

// MARK: - 2. Delegation Protocol
protocol AddFlashcardDelegate: AnyObject {
    func didCreateNewFlashcard(card: Flashcard)
}

// MARK: - 3. View Controller
class FlashcardViewController: UIViewController, AddFlashcardDelegate {

    // MARK: - Outlets
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton! // Acts as Next AND Save
    @IBOutlet weak var countLabel: UILabel!
    
    // MARK: - Data Receivers
    var currentTopic: Topic?
    var parentSubjectName: String?
    
    // MARK: - State
    private var flashcards: [Flashcard] = [
        Flashcard(term: "UIKit", definition: "Apple's framework for building graphical user interfaces for iOS."),
        Flashcard(term: "Auto Layout", definition: "A constraint-based layout system."),
        Flashcard(term: "View Controller", definition: "Manages a set of views and app structure.")
    ]
    
    private var isTermDisplayed = true
    private var currentCardIndex = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let topicName = currentTopic?.name {
            self.title = topicName
        }
        
        configureCardViewAppearance()
        setupTapGesture()
        
        // Initial Update
        updateCardContent(animated: false)
        updateCountLabel()
        updateButtonState() // ✅ Initialize button text
    }
    
    // MARK: - Configuration
    private func configureCardViewAppearance() {
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 8
        cardView.backgroundColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0)
    }

    private func setupTapGesture() {
        cardView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCardTap))
        cardView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - UI Updates
    private func updateCardContent(animated: Bool = true) {
        guard !flashcards.isEmpty else {
            cardLabel.text = "Empty"
            return
        }
        
        let card = flashcards[currentCardIndex]
        let newText = isTermDisplayed ? card.term : card.definition
        
        if animated {
            UIView.transition(with: cardLabel, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.cardLabel.text = newText
            }, completion: nil)
        } else {
            self.cardLabel.text = newText
        }
    }
    
    private func updateCountLabel() {
        guard !flashcards.isEmpty else {
            countLabel.text = "0/0"
            return
        }
        let currentIndex = currentCardIndex + 1
        let total = flashcards.count
        countLabel.text = "\(currentIndex)/\(total)"
    }
    
    // ✅ NEW: Text-Based Button State Logic
    private func updateButtonState() {
        guard !flashcards.isEmpty else { return }
        
        let isLastCard = currentCardIndex == flashcards.count - 1
        
        if isLastCard {
            // Change Text to "Save"
            nextButton.setTitle("Save", for: .normal)
            nextButton.setImage(nil, for: .normal) // Remove any image if present
            nextButton.tintColor = .systemGreen // Optional: Green for Save
        } else {
            // Change Text to "Next" (or reset to arrow if you prefer)
            nextButton.setTitle("Next", for: .normal)
            // If you originally had an arrow image, you can uncomment the line below:
            // nextButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
            nextButton.tintColor = .systemBlue
        }
    }
    
    // MARK: - Actions
    @objc func handleCardTap() {
        guard !flashcards.isEmpty else { return }
        
        let card = flashcards[currentCardIndex]
        let newText = isTermDisplayed ? card.definition : card.term
        let animationOptions: UIView.AnimationOptions = isTermDisplayed ? .transitionFlipFromRight : .transitionFlipFromLeft
        
        UIView.transition(with: cardView, duration: 0.5, options: animationOptions, animations: {
            self.cardLabel.text = newText
        }, completion: nil)
        
        isTermDisplayed.toggle()
    }
    
    @IBAction func nextCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        
        if currentCardIndex < flashcards.count - 1 {
            // CASE 1: Go Next
            currentCardIndex += 1
            isTermDisplayed = true
            updateCardContent()
            updateCountLabel()
            updateButtonState() // Update text to "Save" if we reached the end
        } else {
            // CASE 2: Trigger Save (Since we are at the end)
            saveFlashcards()
        }
    }

    @IBAction func previousCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        
        if currentCardIndex > 0 {
            currentCardIndex -= 1
            isTermDisplayed = true
            updateCardContent()
            updateCountLabel()
            updateButtonState() // Revert text to "Next"
        }
    }
    
    @IBAction func addFlashcardButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "AddCardSegue", sender: self)
    }
    
    // Helper: Save Logic
    func saveFlashcards() {
        // Save Logic (CoreData, etc.) goes here
        showSaveConfirmation()
    }
    
    // Alert Function
    func showSaveConfirmation() {
        let folderName = parentSubjectName ?? "Study"
        
        let alert = UIAlertController(
            title: "Saved!",
            message: "Flashcards have been successfully saved to '\(folderName)'.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddCardSegue" {
            if let navigationController = segue.destination as? UINavigationController,
               let destinationVC = navigationController.topViewController as? AddFlashcardViewController {
                destinationVC.delegate = self
            } else if let destinationVC = segue.destination as? AddFlashcardViewController {
                destinationVC.delegate = self
            }
        }
    }
    
    // MARK: - Delegate Method
    func didCreateNewFlashcard(card: Flashcard) {
        flashcards.append(card)
        updateCardContent(animated: true)
        updateCountLabel()
        updateButtonState() // Check if this new card is the last one
    }
}
