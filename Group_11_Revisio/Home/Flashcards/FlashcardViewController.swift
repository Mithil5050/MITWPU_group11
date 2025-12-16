import UIKit
import Foundation

// MARK: - 1. Flashcard Data Structure (Model)
struct Flashcard {
    let term: String
    let definition: String
}

// NOTE: This protocol must also be defined in AddFlashcardViewController.swift
// MARK: - 2. Delegation Protocol (Receives New Data)
protocol AddFlashcardDelegate: AnyObject {
    func didCreateNewFlashcard(card: Flashcard)
}

// MARK: - 3. View Controller Implementation
class FlashcardViewController: UIViewController, AddFlashcardDelegate {

    // MARK: - View Controller Outlets (Connect these in your Storyboard)
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    // MARK: - State Management
    private var flashcards: [Flashcard] = [
        Flashcard(term: "UIKit", definition: "Apple's framework for building graphical user interfaces for iOS."),
        Flashcard(term: "Auto Layout", definition: "A constraint-based layout system that allows you to define the position and size of your app's views based on rules."),
        Flashcard(term: "View Controller", definition: "An object that manages a set of views and is a core component of your app's structure.")
    ]
    
    private var isTermDisplayed = true
    private var currentCardIndex = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial setup for visual aesthetic and gesture
        configureCardViewAppearance()
        setupTapGesture()
        updateCardContent(animated: false) // Load the first card on launch
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

    /// Sets up the UITapGestureRecognizer programmatically to handle the flip action.
    private func setupTapGesture() {
        cardView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCardTap))
        cardView.addGestureRecognizer(tapGesture)
    }
    
    /// Updates the label text with the current card's content, using a fade animation.
    private func updateCardContent(animated: Bool = true) {
        // Check if there are cards to prevent crashing on an empty array
        guard !flashcards.isEmpty else {
            cardLabel.text = "Tap Add to create a new flashcard."
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
    
    // MARK: - User Interaction: Card Flip (Programmatic Handler)
    
    /// Handles the tap gesture to flip the card between term and definition.
    @objc func handleCardTap() {
        // Prevent flipping if the deck is empty
        guard !flashcards.isEmpty else { return }
        
        let card = flashcards[currentCardIndex]
        let newText = isTermDisplayed ? card.definition : card.term
        
        let animationOptions: UIView.AnimationOptions = isTermDisplayed ? .transitionFlipFromRight : .transitionFlipFromLeft
        
        // Perform the Flip Animation
        UIView.transition(with: cardView, duration: 0.5, options: animationOptions, animations: {
            self.cardLabel.text = newText
        }, completion: nil)
        
        // Toggle the state
        isTermDisplayed.toggle()
    }
    
    // MARK: - User Interaction: Navigation (Storyboard Actions)
    
    /// Moves to the next flashcard in the deck.
    @IBAction func nextCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        isTermDisplayed = true
        currentCardIndex = (currentCardIndex + 1) % flashcards.count
        updateCardContent()
    }

    /// Moves to the previous flashcard in the deck.
    @IBAction func previousCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        isTermDisplayed = true
        currentCardIndex = (currentCardIndex - 1 + flashcards.count) % flashcards.count
        updateCardContent()
    }
    
    // NOTE: Connect this to your "Add" button in Storyboard
    @IBAction func addFlashcardButtonTapped(_ sender: Any) {
        // Trigger the segue to the modal screen (Identifier must be set in Storyboard)
        performSegue(withIdentifier: "AddCardSegue", sender: self)
    }
    
    // MARK: - Segue Preparation (Injecting the Delegate)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddCardSegue" {
            // Check for both direct presentation and presentation within a Navigation Controller
            if let navigationController = segue.destination as? UINavigationController,
               let destinationVC = navigationController.topViewController as? AddFlashcardViewController {
                destinationVC.delegate = self
            } else if let destinationVC = segue.destination as? AddFlashcardViewController {
                 // Direct modal presentation case
                destinationVC.delegate = self
            }
        }
    }
    
    // MARK: - AddFlashcardDelegate Protocol Implementation
    
    /// Receives the new Flashcard object from the modal screen.
    func didCreateNewFlashcard(card: Flashcard) {
        // 💥 CRITICAL STEP: Add the new card to the data source
        flashcards.append(card)
        
        // Update the display to show the newly added card immediately
        currentCardIndex = flashcards.count - 1
        isTermDisplayed = true
        updateCardContent(animated: true)
    }
}
