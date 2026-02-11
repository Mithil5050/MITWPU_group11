import UIKit
import Foundation

// MARK: - 1. Flashcard Data Structure (Model)
struct Flashcards: Codable {
    let term: String
    let definition: String
}

// MARK: - 2. Delegation Protocol (Receives New Data)
protocol AddFlashcardsDelegate: AnyObject {
    func didCreateNewFlashcard(card: Flashcard)
}

// MARK: - 3. View Controller Implementation
class FlashcardsViewController: UIViewController, AddFlashcardsDelegate {

    // MARK: - Outlets
    @IBOutlet weak var cardsView: UIView!
    @IBOutlet weak var cardsLabel: UILabel!
    @IBOutlet weak var previousButtonStudy: UIButton!
    @IBOutlet weak var nextButtonStudy: UIButton!
    @IBOutlet weak var counterLabel: UILabel!
    
    // MARK: - Properties
    var currentTopic: Topic?
    var parentSubjectName: String?
    var isFromGenerationScreen: Bool = false
    
    // Background "Stack" Views
    private var backgroundCard1: UIView!
    private var backgroundCard2: UIView!
    
    // MARK: - State Management
    private var flashcards: [Flashcard] = []
    private var isTermDisplayed = true
    private var currentCardIndex = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCardViewAppearance()
        setupTapGesture()
        
        if let topicName = currentTopic?.name {
            self.title = topicName
        }
        
        
        if let savedContent = currentTopic?.largeContentBody {
            unpackFlashcards(from: savedContent)
        }
        
        
        setupStackVisuals()
        
        updateCardContent(animated: false)
        updateCounterLabel()
    }
    
    // MARK: - UI Configuration & Visuals
    
    private func configureCardViewAppearance() {
        cardsView.layer.cornerRadius = 16
        cardsView.layer.masksToBounds = false
        cardsView.layer.shadowColor = UIColor.black.cgColor
        cardsView.layer.shadowOpacity = 0.1
        cardsView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardsView.layer.shadowRadius = 8
        cardsView.backgroundColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0)
        cardsView.layer.zPosition = 100 // Keeps main card on top
    }

    private func setupStackVisuals() {
        backgroundCard1?.removeFromSuperview()
        backgroundCard2?.removeFromSuperview()
        
        backgroundCard1 = createBackgroundCard()
        backgroundCard2 = createBackgroundCard()
        
        guard let parentView = cardsView.superview else { return }
        parentView.clipsToBounds = false
        
        parentView.insertSubview(backgroundCard1, belowSubview: cardsView)
        parentView.insertSubview(backgroundCard2, belowSubview: backgroundCard1)
        
        NSLayoutConstraint.activate([
            backgroundCard1.centerXAnchor.constraint(equalTo: cardsView.centerXAnchor),
            backgroundCard1.centerYAnchor.constraint(equalTo: cardsView.centerYAnchor),
            backgroundCard1.widthAnchor.constraint(equalTo: cardsView.widthAnchor),
            backgroundCard1.heightAnchor.constraint(equalTo: cardsView.heightAnchor),
            
            backgroundCard2.centerXAnchor.constraint(equalTo: cardsView.centerXAnchor),
            backgroundCard2.centerYAnchor.constraint(equalTo: cardsView.centerYAnchor),
            backgroundCard2.widthAnchor.constraint(equalTo: cardsView.widthAnchor),
            backgroundCard2.heightAnchor.constraint(equalTo: cardsView.heightAnchor)
        ])
        
        resetStackTransforms()
    }

    private func createBackgroundCard() -> UIView {
        let v = UIView()
        v.backgroundColor = cardsView.backgroundColor
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1.0
        v.layer.borderColor = UIColor.black.withAlphaComponent(0.05).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func resetStackTransforms() {
        cardsView.transform = .identity
        cardsView.alpha = 1.0
        // Fanned out look
        backgroundCard1.transform = CGAffineTransform(scaleX: 0.96, y: 0.96).translatedBy(x: 0, y: 24)
        backgroundCard2.transform = CGAffineTransform(scaleX: 0.92, y: 0.92).translatedBy(x: 0, y: 48)
        updateStackVisibility()
    }

    private func updateStackVisibility() {
        let cardsRemaining = flashcards.count - (currentCardIndex + 1)
        UIView.animate(withDuration: 0.3) {
            self.backgroundCard1.alpha = cardsRemaining >= 1 ? 1.0 : 0
            self.backgroundCard2.alpha = cardsRemaining >= 2 ? 1.0 : 0
        }
    }

    private func setupTapGesture() {
        cardsView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCardTap))
        cardsView.addGestureRecognizer(tapGesture)
    }

    // MARK: - User Interaction: Card Flip
    
    @objc func handleCardTap() {
        guard !flashcards.isEmpty else { return }
        let animationOptions: UIView.AnimationOptions = isTermDisplayed ? .transitionFlipFromRight : .transitionFlipFromLeft
        
        UIView.transition(with: cardsView, duration: 0.5, options: animationOptions, animations: {
            let card = self.flashcards[self.currentCardIndex]
            self.cardsLabel.text = self.isTermDisplayed ? card.definition : card.term
        }, completion: { _ in
            self.isTermDisplayed.toggle()
        })
    }

    // MARK: - User Interaction: Navigation (Animations Integrated)

    @IBAction func nextCardButtonTapped(_ sender: UIButton) {
        if isFromGenerationScreen && currentCardIndex == flashcards.count - 1 {
            showSaveConfirmation()
            return
        }
        guard !flashcards.isEmpty, currentCardIndex < flashcards.count - 1 else { return }
        
        
        UIView.animate(withDuration: 0.3, animations: {
            // Swipe Left and Rotate
            let translation = CGAffineTransform(translationX: -self.view.bounds.width, y: -20)
            let rotation = CGAffineTransform(rotationAngle: -0.15)
            self.cardsView.transform = translation.concatenating(rotation)
            self.cardsView.alpha = 0
            
            // Move Stack Up
            self.backgroundCard1.transform = .identity
            self.backgroundCard2.transform = CGAffineTransform(scaleX: 0.96, y: 0.96).translatedBy(x: 0, y: 24)
        }) { _ in
            self.currentCardIndex += 1
            self.isTermDisplayed = true
            self.updateCardContent(animated: false)
            self.resetStackTransforms()
            self.updateCounterLabel()
        }
    }

    @IBAction func previousCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty, currentCardIndex > 0 else { return }
        
        self.currentCardIndex -= 1
        self.isTermDisplayed = true
        self.updateCardContent(animated: false)
        self.updateCounterLabel()
        
        // Prepare Offscreen Right
        let offScreen = CGAffineTransform(translationX: self.view.bounds.width, y: -20).rotated(by: 0.15)
        self.cardsView.transform = offScreen
        self.cardsView.alpha = 0
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.resetStackTransforms()
        }, completion: nil)
    }
    
    // MARK: - Logic & Persistence
    
    private func updateCounterLabel() {
        guard !flashcards.isEmpty else {
            counterLabel?.text = "0/0"
            return
        }
        counterLabel?.text = "\(currentCardIndex + 1)/\(flashcards.count)"
        
        if isFromGenerationScreen && currentCardIndex == flashcards.count - 1 {
            nextButtonStudy.setTitle("Save", for: .normal)
            nextButtonStudy.backgroundColor = .secondarySystemFill
            nextButtonStudy.setTitleColor(.white, for: .normal)
        } else {
            nextButtonStudy.setTitle("Next", for: .normal)
            nextButtonStudy.backgroundColor = .secondarySystemFill
            nextButtonStudy.setTitleColor(.label, for: .normal)
        }
        previousButtonStudy.isEnabled = currentCardIndex > 0
    }
    
    private func updateCardContent(animated: Bool = true) {
        guard !flashcards.isEmpty else {
            cardsLabel.text = "Tap Add to create a new flashcard."
            return
        }
        let card = flashcards[currentCardIndex]
        let newText = isTermDisplayed ? card.term : card.definition
        
        if animated {
            UIView.transition(with: cardsLabel, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.cardsLabel.text = newText
            }, completion: nil)
        } else {
            self.cardsLabel.text = newText
        }
    }
    
    func didCreateNewFlashcard(card: Flashcard) {
        flashcards.append(card)
        let updatedText = flashcards.map { "\($0.term)|\($0.definition)" }.joined(separator: "\n")
        currentTopic?.largeContentBody = updatedText
        
        if let subject = parentSubjectName, let topicName = currentTopic?.name {
            DataManager.shared.updateTopicContent(subject: subject, topicName: topicName, newText: updatedText, type: "Flashcards")
        }
        
        currentCardIndex = flashcards.count - 1
        isTermDisplayed = true
        updateCardContent(animated: true)
        updateCounterLabel()
        resetStackTransforms()
    }

    private func unpackFlashcards(from content: String) {
        let lines = content.components(separatedBy: "\n")
        var loadedCards: [Flashcard] = []
        
        for line in lines where !line.isEmpty {
            let parts = line.components(separatedBy: "|")
            if parts.count == 2 {
                loadedCards.append(Flashcard(term: parts[0], definition: parts[1]))
            }
        }
        
        if !loadedCards.isEmpty {
            self.flashcards = loadedCards
            self.currentCardIndex = 0
            
            // 3. Ensure stack visibility is refreshed now that we have cards
            if backgroundCard1 != nil {
                resetStackTransforms()
            }
        }
    }

    private func showSaveConfirmation() {
        let alert = UIAlertController(title: "Save Flashcards", message: "These cards will be permanently added to your \(parentSubjectName ?? "Study") folder.", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Yes, Save", style: .default) { _ in
            self.persistGeneratedCards()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func persistGeneratedCards() {
        guard let subject = parentSubjectName, let topic = currentTopic else { return }
        let finalContent = flashcards.map { "\($0.term)|\($0.definition)" }.joined(separator: "\n")
        let topicToSave = Topic(name: topic.name, lastAccessed: "Just now", materialType: "Flashcards", parentSubjectName: subject, largeContentBody: finalContent)
        DataManager.shared.addTopic(to: subject, topic: topicToSave)
    }

    @IBAction func addFlashcardButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "addFlashcard", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addFlashcard" {
            let nav = segue.destination as? UINavigationController
            let dest = (nav?.topViewController as? AddFlashcardsViewController) ?? (segue.destination as? AddFlashcardsViewController)
            dest?.delegate = self
        }
    }
}
