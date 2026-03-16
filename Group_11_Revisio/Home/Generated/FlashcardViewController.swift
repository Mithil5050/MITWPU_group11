import UIKit

struct Flashcard {
    let term: String
    let definition: String
}

protocol AddFlashcardDelegate: AnyObject {
    func didCreateNewFlashcard(card: Flashcard)
}

class FlashcardViewController: UIViewController, AddFlashcardDelegate {

    // MARK: - Outlets
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    
    // MARK: - Properties
    var currentTopic: Topic?
    var parentSubjectName: String?
    
    // Background "Stack" Views
    private var backgroundCard1: UIView!
    private var backgroundCard2: UIView!
    
    private var flashcards: [Flashcard] = []
    private var isTermDisplayed = true
    private var currentCardIndex = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let topicName = currentTopic?.name {
            self.title = topicName
        }
        
        // ✅ LOAD DATA: Check largeContentBody first, fallback to notesContent for backwards compatibility
        if let content = currentTopic?.largeContentBody, !content.isEmpty {
            unpackFlashcards(from: content)
        } else if let fallbackContent = currentTopic?.notesContent, !fallbackContent.isEmpty {
            unpackFlashcards(from: fallbackContent)
        }
        
        // 1. Setup Main Card (Color is set here)
        setupCardView()
        
        // 2. Setup Stack (Inherits color from Main Card)
        setupStackVisuals()
        
        setupGesture()
        updateUI(animated: false)
    }
    
    // ✅ EXTRACT SAVED DATA
    private func unpackFlashcards(from content: String) {
        let lines = content.components(separatedBy: "\n")
        var loaded: [Flashcard] = []
        for line in lines where !line.isEmpty {
            let parts = line.components(separatedBy: "|")
            if parts.count >= 2 {
                loaded.append(Flashcard(term: parts[0], definition: parts[1]))
            }
        }
        if !loaded.isEmpty {
            self.flashcards = loaded
        }
    }
    
    // MARK: - UI Setup
    private func setupCardView() {
        cardView.backgroundColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0)
        styleCard(cardView)
        cardView.layer.zPosition = 100
    }
    
    private func setupStackVisuals() {
        backgroundCard1?.removeFromSuperview()
        backgroundCard2?.removeFromSuperview()
        
        backgroundCard1 = createBackgroundCard()
        backgroundCard2 = createBackgroundCard()
        
        guard let parentView = cardView.superview else { return }
        parentView.clipsToBounds = false
        
        parentView.insertSubview(backgroundCard1, belowSubview: cardView)
        parentView.insertSubview(backgroundCard2, belowSubview: backgroundCard1)
        
        alignBackgroundCard(backgroundCard1)
        alignBackgroundCard(backgroundCard2)
        
        resetStackTransforms()
    }
    
    private func createBackgroundCard() -> UIView {
        let v = UIView()
        v.backgroundColor = cardView.backgroundColor
        styleCard(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }
    
    private func styleCard(_ view: UIView) {
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
        view.layer.masksToBounds = false
    }
    
    private func alignBackgroundCard(_ bgView: UIView) {
        NSLayoutConstraint.activate([
            bgView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            bgView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            bgView.widthAnchor.constraint(equalTo: cardView.widthAnchor),
            bgView.heightAnchor.constraint(equalTo: cardView.heightAnchor)
        ])
    }
    
    private func resetStackTransforms() {
        cardView.transform = .identity
        cardView.alpha = 1.0
        
        backgroundCard1.transform = CGAffineTransform(scaleX: 0.96, y: 0.96).translatedBy(x: 0, y: 24)
        backgroundCard1.alpha = 1.0
        
        backgroundCard2.transform = CGAffineTransform(scaleX: 0.92, y: 0.92).translatedBy(x: 0, y: 48)
        backgroundCard2.alpha = 1.0
        
        updateStackVisibility()
    }
    
    private func updateStackVisibility() {
        let cardsRemaining = flashcards.count - (currentCardIndex + 1)
        UIView.animate(withDuration: 0.2) {
            self.backgroundCard1.isHidden = cardsRemaining < 1
            self.backgroundCard2.isHidden = cardsRemaining < 2
        }
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleCardTap))
        cardView.addGestureRecognizer(tap)
    }
    
    // MARK: - Actions
    @objc func handleCardTap() {
        guard !flashcards.isEmpty else { return }
        isTermDisplayed.toggle()
        updateUI(animated: true)
    }
    
    @IBAction func nextCardButtonTapped(_ sender: UIButton) {
        if currentCardIndex < flashcards.count - 1 {
            animateNextCard()
        } else {
            handleSave()
        }
    }

    @IBAction func previousCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty, currentCardIndex > 0 else { return }
        animatePreviousCard()
    }
    
    @IBAction func addFlashcardButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "AddCardSegue", sender: self)
    }
    
    // MARK: - Animations
    private func animateNextCard() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            let translation = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
            let rotation = CGAffineTransform(rotationAngle: -0.15)
            self.cardView.transform = translation.concatenating(rotation)
            
            self.backgroundCard1.transform = .identity
            self.backgroundCard2.transform = CGAffineTransform(scaleX: 0.96, y: 0.96).translatedBy(x: 0, y: 24)
            
        }) { _ in
            self.currentCardIndex += 1
            self.isTermDisplayed = true
            self.updateUI(animated: false)
            
            self.cardView.transform = .identity
            self.resetStackTransforms()
        }
    }
    
    private func animatePreviousCard() {
        self.currentCardIndex -= 1
        self.isTermDisplayed = true
        self.updateUI(animated: false)
        
        let offScreen = CGAffineTransform(translationX: self.view.bounds.width, y: 0).rotated(by: 0.15)
        self.cardView.transform = offScreen
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.cardView.transform = .identity
            self.backgroundCard1.transform = CGAffineTransform(scaleX: 0.96, y: 0.96).translatedBy(x: 0, y: 24)
            self.backgroundCard2.transform = CGAffineTransform(scaleX: 0.92, y: 0.92).translatedBy(x: 0, y: 48)
        }) { _ in
            self.resetStackTransforms()
        }
    }

    // MARK: - UI Updates
    func updateUI(animated: Bool = false) {
        // ✅ Safely handle 0 cards state
        guard !flashcards.isEmpty else {
            cardLabel.text = "No flashcards available.\nTap '+' to add one."
            countLabel.text = "0 / 0"
            previousButton.isEnabled = false
            nextButton.isEnabled = false
            updateStackVisibility()
            return
        }
        
        let card = flashcards[currentCardIndex]
        let text = isTermDisplayed ? card.term : card.definition
        
        countLabel.text = "\(currentCardIndex + 1) / \(flashcards.count)"
        
        if animated {
            UIView.transition(with: cardView, duration: 0.3, options: .transitionFlipFromRight, animations: {
                self.cardLabel.text = text
            }, completion: nil)
        } else {
            self.cardLabel.text = text
        }
        
        previousButton.isEnabled = currentCardIndex > 0
        if currentCardIndex == flashcards.count - 1 {
            nextButton.setTitle("Done", for: .normal)
            nextButton.tintColor = .systemGreen
        } else {
            nextButton.setTitle("Next", for: .normal)
            nextButton.tintColor = .systemBlue
        }
        nextButton.isEnabled = true
        
        updateStackVisibility()
    }
    
    private func handleSave() {
        let folderName = parentSubjectName ?? "Study"
        
        let alert = UIAlertController(
            title: "Session Complete",
            message: "These cards will be permanently added to your '\(folderName)' folder.",
            preferredStyle: .alert
        )
        
        let saveAction = UIAlertAction(title: "Yes, Save", style: .default) { [weak self] _ in
            guard let self = self else { return }
            ProgressDataManager.shared.logSession(minutes: Double(self.flashcards.count) * 0.5, category: "Study")
            let confirmAlert = UIAlertController(title: "Saved!", message: "Your progress has been recorded.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                if let nav = self.navigationController {
                    nav.popToRootViewController(animated: true)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            confirmAlert.addAction(okAction)
            self.present(confirmAlert, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { _ in
            self.resetStackTransforms()
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    // MARK: - Navigation / Delegate
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
        ProgressDataManager.shared.totalFlashcardsViewed += 1
        flashcards.append(card)
        let updatedText = flashcards.map { "\($0.term)|\($0.definition)" }.joined(separator: "\n")
        currentTopic?.largeContentBody = updatedText
        
        if let subject = parentSubjectName, let topicName = currentTopic?.name {
            DataManager.shared.updateTopicContent(subject: subject, topicName: topicName, newText: updatedText, type: "Flashcards")
        }
        
        currentCardIndex = flashcards.count - 1
        isTermDisplayed = true
        updateUI(animated: true)
        resetStackTransforms()
    }
}
