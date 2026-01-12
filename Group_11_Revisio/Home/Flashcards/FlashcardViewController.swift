import UIKit
import Foundation

// MARK: - 1. Flashcard Data Structure (Model)
struct Flashcard {
    let term: String
    let definition: String
}

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
        
        configureCardViewAppearance()
        setupTapGesture()
        updateCardContent(animated: false)
    }
    
    // MARK: - Private Configuration Methods
    
    private func configureCardViewAppearance() {
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 8
        cardView.backgroundColor = UIColor(hex: "91C1EF")
    }

    private func setupTapGesture() {
        cardView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCardTap))
        cardView.addGestureRecognizer(tapGesture)
    }
    
    private func updateCardContent(animated: Bool = true) {

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
    
    // MARK: - User Interaction: Navigation (Storyboard Actions)
    
    @IBAction func nextCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        isTermDisplayed = true
        currentCardIndex = (currentCardIndex + 1) % flashcards.count
        updateCardContent()
    }

    @IBAction func previousCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        isTermDisplayed = true
        currentCardIndex = (currentCardIndex - 1 + flashcards.count) % flashcards.count
        updateCardContent()
    }
    
    @IBAction func addFlashcardButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "AddCardSegue", sender: self)
    }
    
    // MARK: - Segue Preparation (Injecting the Delegate)
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
    
    //  AddFlashcardDelegate Protocol Implementation
    
    func didCreateNewFlashcard(card: Flashcard) {
        flashcards.append(card)
        
        currentCardIndex = flashcards.count - 1
        isTermDisplayed = true
        updateCardContent(animated: true)
    }
}
