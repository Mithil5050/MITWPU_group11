import UIKit

struct Flashcard {
    let term: String
    let definition: String
}

protocol AddFlashcardDelegate: AnyObject {
    func didCreateNewFlashcard(card: Flashcard)
}

class FlashcardViewController: UIViewController, AddFlashcardDelegate {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    
    var currentTopic: Topic?
    var parentSubjectName: String?
    
    private var flashcards: [Flashcard] = [
        Flashcard(term: "UIKit", definition: "Apple's framework for building graphical user interfaces for iOS."),
        Flashcard(term: "Auto Layout", definition: "A constraint-based layout system."),
        Flashcard(term: "View Controller", definition: "Manages a set of views and app structure.")
    ]
    
    private var isTermDisplayed = true
    private var currentCardIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let topicName = currentTopic?.name {
            self.title = topicName
        }
        
        setupCardView()
        setupGesture()
        updateUI(animated: false)
    }
    
    private func setupCardView() {
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 8
        cardView.backgroundColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0)
    }

    private func setupGesture() {
        cardView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCardFlip))
        cardView.addGestureRecognizer(tapGesture)
    }
    
    private func updateUI(animated: Bool = true) {
        guard !flashcards.isEmpty else {
            cardLabel.text = "Empty"
            countLabel.text = "0/0"
            return
        }
        
        let card = flashcards[currentCardIndex]
        let text = isTermDisplayed ? card.term : card.definition
        
        if animated {
            UIView.transition(with: cardLabel, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.cardLabel.text = text
            })
        } else {
            cardLabel.text = text
        }
        
        countLabel.text = "\(currentCardIndex + 1)/\(flashcards.count)"
        updateNavigationState()
    }
    
    private func updateNavigationState() {
        let isLastCard = currentCardIndex == flashcards.count - 1
        
        if isLastCard {
            nextButton.setTitle("Save", for: .normal)
            nextButton.setImage(nil, for: .normal)
            nextButton.tintColor = .systemGreen
        } else {
            nextButton.setTitle("Next", for: .normal)
            nextButton.tintColor = .systemBlue
        }
        
        previousButton.isEnabled = currentCardIndex > 0
    }
    
    @objc private func handleCardFlip() {
        guard !flashcards.isEmpty else { return }
        
        let card = flashcards[currentCardIndex]
        let newText = isTermDisplayed ? card.definition : card.term
        let options: UIView.AnimationOptions = isTermDisplayed ? .transitionFlipFromRight : .transitionFlipFromLeft
        
        UIView.transition(with: cardView, duration: 0.5, options: options, animations: {
            self.cardLabel.text = newText
        })
        
        isTermDisplayed.toggle()
    }
    
    @IBAction func nextCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        
        if currentCardIndex < flashcards.count - 1 {
            currentCardIndex += 1
            isTermDisplayed = true
            updateUI()
        } else {
            handleSave()
        }
    }

    @IBAction func previousCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty, currentCardIndex > 0 else { return }
        
        currentCardIndex -= 1
        isTermDisplayed = true
        updateUI()
    }
    
    @IBAction func addFlashcardButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "AddCardSegue", sender: self)
    }
    
    private func handleSave() {
        let folderName = parentSubjectName ?? "Study"
        let alert = UIAlertController(title: "Saved!", message: "Flashcards saved to '\(folderName)'.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddCardSegue" {
            let destinationVC: AddFlashcardViewController?
            
            if let nav = segue.destination as? UINavigationController {
                destinationVC = nav.topViewController as? AddFlashcardViewController
            } else {
                destinationVC = segue.destination as? AddFlashcardViewController
            }
            
            destinationVC?.delegate = self
        }
    }
    
    func didCreateNewFlashcard(card: Flashcard) {
        flashcards.append(card)
        updateUI()
    }
}
