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
    @IBOutlet weak var nextButton: UIButton!
    
    // IMPORTANT: Connect this to the "1/5" label in Storyboard
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
    }
    
    // MARK: - Configuration
    private func configureCardViewAppearance() {
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 8
        
        // ✅ FIXED: Using standard RGB values instead of Hex Extension to prevent errors.
        // This is the same blue color (91C1EF)
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
    
    // ✅ DYNAMIC LABEL LOGIC
    private func updateCountLabel() {
        guard !flashcards.isEmpty else {
            countLabel.text = "0/0"
            return
        }
        let currentIndex = currentCardIndex + 1
        let total = flashcards.count
        countLabel.text = "\(currentIndex)/\(total)"
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
        isTermDisplayed = true
        currentCardIndex = (currentCardIndex + 1) % flashcards.count
        
        updateCardContent()
        updateCountLabel() // Update label
    }

    @IBAction func previousCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        isTermDisplayed = true
        currentCardIndex = (currentCardIndex - 1 + flashcards.count) % flashcards.count
        
        updateCardContent()
        updateCountLabel() // Update label
    }
    
    @IBAction func addFlashcardButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "AddCardSegue", sender: self)
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
        currentCardIndex = flashcards.count - 1
        isTermDisplayed = true
        
        updateCardContent(animated: true)
        updateCountLabel() // Update label
    }
}
