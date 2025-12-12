import UIKit

// MARK: - 1. Flashcard Data Structure
struct Flashcard {
    let term: String
    let definition: String
}

// MARK: - 2. Sample Data for Prototype
var flashcards: [Flashcard] = [
    Flashcard(term: "UIKit", definition: "Apple's framework for building graphical user interfaces for iOS."),
    Flashcard(term: "Auto Layout", definition: "A constraint-based layout system that allows you to define the position and size of your app's views based on rules."),
    Flashcard(term: "View Controller", definition: "An object that manages a set of views and is a core component of your app's structure.")
]

// MARK: - 3. View Controller Implementation
class FlashcardViewController: UIViewController {

    // MARK: - View Controller Outlets (Connect these in your Storyboard)
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    // MARK: - State Management
    private var isTermDisplayed = true
    private var currentCardIndex = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial setup
        configureCardViewAppearance()
        updateCardContent(animated: false) // Load the first card without animation
    }
    
    // MARK: - Private Configuration Methods
    
    /// Applies the modern iOS 26 visual aesthetic to the card view.
    private func configureCardViewAppearance() {
        // Aesthetic: Rounded corners and a subtle shadow for depth
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 8
    }

    /// Updates the label text with the current card's content.
    private func updateCardContent(animated: Bool = true) {
        let card = flashcards[currentCardIndex]
        let newText = isTermDisplayed ? card.term : card.definition
        
        if animated {
            // Use a subtle cross-dissolve for smooth card-to-card transitions
            UIView.transition(with: cardLabel, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.cardLabel.text = newText
            }, completion: nil)
        } else {
            self.cardLabel.text = newText
        }
    }
    
    // MARK: - User Interaction: Card Flip
    
    /// Handles the tap gesture to flip the card between term and definition.
    @IBAction func cardTapped(_ sender: UITapGestureRecognizer) {
        let card = flashcards[currentCardIndex]
        let newText = isTermDisplayed ? card.definition : card.term
        
        // Use the appropriate transition option for a visually pleasing flip
        let animationOptions: UIView.AnimationOptions = isTermDisplayed ? .transitionFlipFromRight : .transitionFlipFromLeft
        
        UIView.transition(with: cardView, duration: 0.5, options: animationOptions, animations: {
            self.cardLabel.text = newText
        }, completion: nil)
        
        // Toggle the state
        isTermDisplayed.toggle()
    }
    
    // MARK: - User Interaction: Navigation
    
    /// Moves to the next flashcard in the deck.
    @IBAction func nextCardButtonTapped(_ sender: UIButton) {
        // Ensure the card flips back to the term before showing the next one
        isTermDisplayed = true
        
        // Cycle to the next card index, looping to the start if at the end
        currentCardIndex = (currentCardIndex + 1) % flashcards.count
        
        updateCardContent()
    }

    /// Moves to the previous flashcard in the deck.
    @IBAction func previousCardButtonTapped(_ sender: UIButton) {
        // Ensure the card flips back to the term before showing the next one
        isTermDisplayed = true
        
        // Cycle to the previous card index, looping to the end if at the start
        currentCardIndex = (currentCardIndex - 1 + flashcards.count) % flashcards.count
        
        updateCardContent()
    }
}
