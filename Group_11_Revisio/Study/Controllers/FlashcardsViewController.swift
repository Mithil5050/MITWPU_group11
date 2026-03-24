import UIKit
import Foundation

// MARK: - 1. Flashcard Data Structure (Model)
struct Flashcards: Codable {
    let term: String
    let definition: String
    let keyword: String
}

// MARK: - 2. Delegation Protocol (Receives New Data)
protocol AddFlashcardsDelegate: AnyObject {
    func didCreateNewFlashcard(card: Flashcard)
}

// MARK: - 3. View Controller Implementation
class FlashcardsViewController: UIViewController, AddFlashcardsDelegate, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var cardsView: UIView!
    @IBOutlet weak var cardsLabel: UILabel!
    

    private let challengeModeSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let challengeModeLabel: UILabel = {
        let label = UILabel()
        label.text = "Challenge Mode"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let challengeTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Type keyword here..."
        tf.borderStyle = .roundedRect
        tf.textAlignment = .center
        tf.isHidden = true
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    

    

    private var initialCardCenter: CGPoint = .zero
    
    // MARK: - Properties
    var currentTopic: Topic?
    var parentSubjectName: String?
    var isFromGenerationScreen: Bool = false
    
   
    private var backgroundCard1: UIView!
    private var backgroundCard2: UIView!
    
    // MARK: - State Management
    private var flashcards: [Flashcard] = []
    private var isTermDisplayed = true
    private var currentCardIndex = 0
    
    private var knownCount = 0
    private var unknownCount = 0
    private let resultsOverlay = UIView()

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
        
        setupProgrammaticUI()
        
        challengeModeSwitch.addTarget(self, action: #selector(toggleChallengeMode), for: .valueChanged)
        challengeTextField.delegate = self
        challengeTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        updateCardContent(animated: false)
        updateCounterLabel()
    }
    
    private func setupProgrammaticUI() {

        view.addSubview(challengeModeSwitch)
        view.addSubview(challengeModeLabel)
        view.addSubview(challengeTextField)
        
        NSLayoutConstraint.activate([
            cardsView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55)
        ])
        
        NSLayoutConstraint.activate([

            challengeModeSwitch.topAnchor.constraint(equalTo: cardsView.bottomAnchor, constant: 40),
            challengeModeSwitch.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -60),
            
            challengeModeLabel.centerYAnchor.constraint(equalTo: challengeModeSwitch.centerYAnchor),
            challengeModeLabel.leadingAnchor.constraint(equalTo: challengeModeSwitch.trailingAnchor, constant: 10),
            
            challengeTextField.topAnchor.constraint(equalTo: challengeModeSwitch.bottomAnchor, constant: 20),
            challengeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            challengeTextField.widthAnchor.constraint(equalToConstant: 250),
            challengeTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func toggleChallengeMode() {
        let isChallenge = challengeModeSwitch.isOn
        challengeTextField.isHidden = !isChallenge
        if isChallenge {
            challengeTextField.text = ""
            isTermDisplayed = true
            updateCardContent(animated: true)
        } else {
            challengeTextField.resignFirstResponder()
            cardsView.isUserInteractionEnabled = true
        }
    }
    
    @objc private func textFieldDidChange() {
        guard challengeModeSwitch.isOn, let text = challengeTextField.text, !flashcards.isEmpty else { return }
        
        // Use term as fallback if keyword is missing or empty (for old generated ones)
        let currentCard = flashcards[currentCardIndex]
        let currentKeyword = currentCard.keyword.isEmpty ? currentCard.term.lowercased() : currentCard.keyword.lowercased()
        
        if text.lowercased().contains(currentKeyword) || text.lowercased() == currentKeyword {
            challengeModeSuccess()
        }
    }
    
    private func challengeModeSuccess() {
        challengeTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.3) {
            self.cardsView.backgroundColor = .systemGreen
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.configureCardViewAppearance() // Revert color
            }
            self.isTermDisplayed = false
            self.updateCardContent(animated: true)
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard challengeModeSwitch.isOn, let text = textField.text, !flashcards.isEmpty else { return false }
        
        let currentCard = flashcards[currentCardIndex]
        let currentKeyword = currentCard.keyword.isEmpty ? currentCard.term.lowercased() : currentCard.keyword.lowercased()
        
        if text.lowercased().contains(currentKeyword) || text.lowercased() == currentKeyword {
            challengeModeSuccess()
            return true
        } else {
            shakeCardRed()
            return false
        }
    }
    
    private func shakeCardRed() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, -2.0, 2.0, 0.0]
        cardsView.layer.add(animation, forKey: "shake")
        
        let originalColor = cardsView.backgroundColor
        let originalBorder = cardsView.layer.borderColor
        
        UIView.animate(withDuration: 0.1, animations: {
            self.cardsView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
            self.cardsView.layer.borderColor = UIColor.systemRed.cgColor
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.2, animations: {
                self.cardsView.backgroundColor = originalColor
                self.cardsView.layer.borderColor = originalBorder
            }, completion: nil)
        }
    }
    
    // MARK: - UI Configuration & Visuals
    
    private func configureCardViewAppearance() {
        cardsView.layer.cornerRadius = 16
        cardsView.layer.masksToBounds = false
        cardsView.layer.shadowColor = UIColor.black.cgColor
        cardsView.layer.shadowOpacity = 0.1
        cardsView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardsView.layer.shadowRadius = 8
        cardsView.backgroundColor = .systemGray6
        cardsView.layer.borderWidth = 3.0
        cardsView.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        cardsView.layer.zPosition = 100
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
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 3.0
        v.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func resetStackTransforms() {
        cardsView.transform = .identity
        cardsView.alpha = 1.0
        
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
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        cardsView.addGestureRecognizer(pan)
    }

    // MARK: - User Interaction: Card Flip
    
    @objc func handleCardTap() {
        guard !flashcards.isEmpty else { return }
        if challengeModeSwitch.isOn && isTermDisplayed {
            return
        }
        let animationOptions: UIView.AnimationOptions = isTermDisplayed ? .transitionFlipFromRight : .transitionFlipFromLeft
        
        UIView.transition(with: cardsView, duration: 0.5, options: animationOptions, animations: {
            let card = self.flashcards[self.currentCardIndex]
            self.cardsLabel.text = self.isTermDisplayed ? card.definition : card.term
        }, completion: { _ in
            self.isTermDisplayed.toggle()
        })
    }

    // MARK: - User Interaction: Navigation (Animations Integrated)

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard !flashcards.isEmpty else { return }
        guard let card = sender.view else { return }
        
        if challengeModeSwitch.isOn && isTermDisplayed {
            return
        }
        
        let translation = sender.translation(in: view)
        
        switch sender.state {
        case .began:
            initialCardCenter = card.center
        case .changed:
            let rotation = (translation.x / view.bounds.width) * 0.4
            card.transform = CGAffineTransform(translationX: translation.x, y: translation.y).rotated(by: rotation)
            
            if translation.x > 0 {
                card.layer.borderColor = UIColor.systemGreen.cgColor
                card.layer.borderWidth = 3.0
            } else {
                card.layer.borderColor = UIColor.systemRed.cgColor
                card.layer.borderWidth = 3.0
            }
        case .ended:
            card.layer.borderWidth = 3.0
            card.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
            
            if translation.x > 150 {
                swipeRight(card: card)
            } else if translation.x < -150 {
                swipeLeft(card: card)
            } else {
                UIView.animate(withDuration: 0.3) {
                    card.center = self.initialCardCenter
                    card.transform = .identity
                }
            }
        default:
            break
        }
    }
    
    private func swipeRight(card: UIView) {
        knownCount += 1
        finishSwipe(translationX: view.bounds.width)
    }
    
    private func swipeLeft(card: UIView) {
        unknownCount += 1
        finishSwipe(translationX: -view.bounds.width)
    }
    
    private func finishSwipe(translationX: CGFloat) {
        UIView.animate(withDuration: 0.3, animations: {
            self.cardsView.transform = CGAffineTransform(translationX: translationX, y: 0).rotated(by: translationX > 0 ? 0.3 : -0.3)
            self.cardsView.alpha = 0
            
            self.backgroundCard1.transform = .identity
            self.backgroundCard2.transform = CGAffineTransform(scaleX: 0.96, y: 0.96).translatedBy(x: 0, y: 24)
        }) { _ in
            self.cardsView.transform = .identity
            self.cardsView.alpha = 1.0
            self.cardsView.center = self.initialCardCenter
            
            if self.isFromGenerationScreen && self.currentCardIndex == self.flashcards.count - 1 {
                self.showResultsOverlay()
                return
            }
            
            if self.currentCardIndex < self.flashcards.count - 1 {
                self.currentCardIndex += 1
                self.isTermDisplayed = true
                self.updateCardContent(animated: false)
                self.resetStackTransforms()
                self.updateCounterLabel()
            } else {
                self.cardsView.isHidden = true
                self.challengeModeSwitch.isHidden = true
                self.challengeModeLabel.isHidden = true
                self.challengeTextField.isHidden = true
                self.showResultsOverlay()
            }
        }
    }

    private func showResultsOverlay() {
        resultsOverlay.translatesAutoresizingMaskIntoConstraints = false
        resultsOverlay.backgroundColor = .systemGray6
        resultsOverlay.layer.cornerRadius = 16
        resultsOverlay.layer.borderWidth = 3.0
        resultsOverlay.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        resultsOverlay.layer.shadowColor = UIColor.black.cgColor
        resultsOverlay.layer.shadowOpacity = 0.15
        resultsOverlay.layer.shadowOffset = CGSize(width: 0, height: 4)
        resultsOverlay.layer.shadowRadius = 6
        resultsOverlay.alpha = 0
        view.addSubview(resultsOverlay)
        
        let titleLabel = UILabel()
        titleLabel.text = "Study Complete! 🎉"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let knownLabel = UILabel()
        knownLabel.text = "✅ Known: \\(knownCount)"
        knownLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        knownLabel.textColor = .systemGreen
        knownLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let unknownLabel = UILabel()
        unknownLabel.text = "❌ Need Review: \\(unknownCount)"
        unknownLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        unknownLabel.textColor = .systemRed
        unknownLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        doneButton.backgroundColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.cornerRadius = 12
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(handleDone), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, knownLabel, unknownLabel, doneButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        resultsOverlay.addSubview(stack)
        
        NSLayoutConstraint.activate([
            resultsOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultsOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            resultsOverlay.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            resultsOverlay.heightAnchor.constraint(equalToConstant: 280),
            
            stack.centerXAnchor.constraint(equalTo: resultsOverlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: resultsOverlay.centerYAnchor),
            
            doneButton.widthAnchor.constraint(equalToConstant: 200),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        UIView.animate(withDuration: 0.5) {
            self.resultsOverlay.alpha = 1.0
        }
    }
    
    @objc private func handleDone() {
        if isFromGenerationScreen {
            showSaveConfirmation()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }


    
    // MARK: - Logic & Persistence
    
    private func updateCounterLabel() {}
    
    private func updateCardContent(animated: Bool = true) {
        guard !flashcards.isEmpty else {
            cardsLabel.text = "Tap Add to create a new flashcard."
            return
        }
        let card = flashcards[currentCardIndex]
        let newText = isTermDisplayed ? card.term : card.definition
        
        if challengeModeSwitch.isOn && isTermDisplayed {
            challengeTextField.text = ""
            cardsView.isUserInteractionEnabled = false
        } else {
            cardsView.isUserInteractionEnabled = true
        }
        
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
        let updatedText = flashcards.map { "\($0.term)|\($0.definition)|\($0.keyword)" }.joined(separator: "\n")
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
            if parts.count >= 3 {
                loadedCards.append(Flashcard(term: parts[0], definition: parts[1], keyword: parts[2]))
            } else if parts.count >= 2 {
                loadedCards.append(Flashcard(term: parts[0], definition: parts[1], keyword: parts[0]))
            }
        }
        
        if !loadedCards.isEmpty {
            self.flashcards = loadedCards
            self.currentCardIndex = 0
            
          
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
        let finalContent = flashcards.map { "\($0.term)|\($0.definition)|\($0.keyword)" }.joined(separator: "\n")
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
