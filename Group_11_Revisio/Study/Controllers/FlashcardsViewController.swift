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
        
        // --- LOGIC CHANGE: Smart Naming (Internal Logic Only) ---
        if let topicName = currentTopic?.name {
            let cleanTitle = topicName.replacingOccurrences(of: ".txt", with: "")
                                      .replacingOccurrences(of: "Note_", with: "")
                                      .replacingOccurrences(of: "Link_", with: "")
                                      .replacingOccurrences(of: "_", with: " ")
            self.title = cleanTitle
        }
        
        // --- LOGIC CHANGE: Fixed Hyphenation Error ---
        cardsLabel.numberOfLines = 0
        // We set initial style here
        updateLabelText("")
        
        configureCardViewAppearance()
        setupTapGesture()
        
        if let savedContent = currentTopic?.largeContentBody, !savedContent.isEmpty {
            unpackFlashcards(from: savedContent)
        } else if let fallbackContent = currentTopic?.notesContent {
            unpackFlashcards(from: fallbackContent)
        }
        
        setupStackVisuals()
        setupProgrammaticUI()
        
        challengeModeSwitch.addTarget(self, action: #selector(toggleChallengeMode), for: .valueChanged)
        challengeTextField.delegate = self
        challengeTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        updateCardContent(animated: false)
    }
    
    // Helper to handle the text logic without hyphenation errors
    private func updateLabelText(_ text: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = 0.0
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: cardsLabel.font ?? UIFont.systemFont(ofSize: 18)
        ]
        cardsLabel.attributedText = NSAttributedString(string: text, attributes: attributes)
    }

    private func setupProgrammaticUI() {
        view.addSubview(challengeModeSwitch)
        view.addSubview(challengeModeLabel)
        view.addSubview(challengeTextField)
        
        NSLayoutConstraint.activate([
            cardsView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55),
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
            challengeTextField.becomeFirstResponder()
        } else {
            challengeTextField.resignFirstResponder()
            cardsView.isUserInteractionEnabled = true
        }
    }
    
    @objc private func textFieldDidChange() {
        guard challengeModeSwitch.isOn, let text = challengeTextField.text?.trimmingCharacters(in: .whitespaces), !flashcards.isEmpty else { return }
        
        let currentCard = flashcards[currentCardIndex]
        let currentKeyword = currentCard.keyword.isEmpty ? currentCard.term.lowercased() : currentCard.keyword.lowercased()
        
        if text.lowercased() == currentKeyword {
            challengeModeSuccess()
        }
    }
    
    private func challengeModeSuccess() {
        challengeTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.3) {
            self.cardsView.backgroundColor = .systemGreen
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.configureCardViewAppearance()
            }
            self.isTermDisplayed = false
            self.updateCardContent(animated: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if challengeModeSwitch.isOn && isTermDisplayed {
            shakeCardRed()
        }
        textField.resignFirstResponder()
        return true
    }
    
    private func shakeCardRed() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, -2.0, 2.0, 0.0]
        cardsView.layer.add(animation, forKey: "shake")
        
        let originalColor = cardsView.backgroundColor
        UIView.animate(withDuration: 0.1, animations: {
            self.cardsView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.2, animations: {
                self.cardsView.backgroundColor = originalColor
            })
        }
    }
    
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
        backgroundCard1.transform = CGAffineTransform(scaleX: 0.96, y: 0.96).translatedBy(x: 0, y: 24)
        backgroundCard2.transform = CGAffineTransform(scaleX: 0.92, y: 0.92).translatedBy(x: 0, y: 48)
        updateStackVisibility()
    }

    private func updateStackVisibility() {
        let remaining = flashcards.count - (currentCardIndex + 1)
        UIView.animate(withDuration: 0.3) {
            self.backgroundCard1.alpha = remaining >= 1 ? 1.0 : 0
            self.backgroundCard2.alpha = remaining >= 2 ? 1.0 : 0
        }
    }

    private func setupTapGesture() {
        cardsView.isUserInteractionEnabled = true
        cardsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleCardTap)))
        cardsView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
    }

    @objc func handleCardTap() {
        guard !flashcards.isEmpty else { return }
        if challengeModeSwitch.isOn && isTermDisplayed { return }
        
        UIView.transition(with: cardsView, duration: 0.5, options: isTermDisplayed ? .transitionFlipFromRight : .transitionFlipFromLeft, animations: {
            let card = self.flashcards[self.currentCardIndex]
            self.updateLabelText(self.isTermDisplayed ? card.definition : card.term)
        }, completion: { _ in
            self.isTermDisplayed.toggle()
        })
    }

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard !flashcards.isEmpty, let card = sender.view else { return }
        if challengeModeSwitch.isOn && isTermDisplayed { return }
        
        let translation = sender.translation(in: view)
        switch sender.state {
        case .began: initialCardCenter = card.center
        case .changed:
            let rotation = (translation.x / view.bounds.width) * 0.4
            card.transform = CGAffineTransform(translationX: translation.x, y: translation.y).rotated(by: rotation)
            card.layer.borderColor = translation.x > 0 ? UIColor.systemGreen.cgColor : UIColor.systemRed.cgColor
        case .ended:
            if abs(translation.x) > 150 {
                translation.x > 0 ? (knownCount += 1) : (unknownCount += 1)
                finishSwipe(translationX: translation.x > 0 ? view.bounds.width : -view.bounds.width)
            } else {
                UIView.animate(withDuration: 0.3) {
                    card.center = self.initialCardCenter
                    card.transform = .identity
                    card.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
                }
            }
        default: break
        }
    }

    private func finishSwipe(translationX: CGFloat) {
        UIView.animate(withDuration: 0.3, animations: {
            self.cardsView.transform = CGAffineTransform(translationX: translationX, y: 0).rotated(by: translationX > 0 ? 0.3 : -0.3)
            self.cardsView.alpha = 0
        }) { _ in
            self.cardsView.transform = .identity
            self.cardsView.alpha = 1.0
            self.cardsView.center = self.initialCardCenter
            self.configureCardViewAppearance()
            
            if self.currentCardIndex < self.flashcards.count - 1 {
                self.currentCardIndex += 1
                self.isTermDisplayed = true
                self.updateCardContent(animated: false)
                self.resetStackTransforms()
            } else {
                self.cardsView.isHidden = true
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
        resultsOverlay.alpha = 0
        view.addSubview(resultsOverlay)
        
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(handleDone), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [UILabel(), doneButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        resultsOverlay.addSubview(stack)
        
        NSLayoutConstraint.activate([
            resultsOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultsOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            resultsOverlay.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            resultsOverlay.heightAnchor.constraint(equalToConstant: 200),
            stack.centerXAnchor.constraint(equalTo: resultsOverlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: resultsOverlay.centerYAnchor)
        ])
        
        UIView.animate(withDuration: 0.5) { self.resultsOverlay.alpha = 1.0 }
    }

    @objc private func handleDone() {
        if isFromGenerationScreen {
            showSaveConfirmation()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    private func updateCardContent(animated: Bool = true) {
        guard !flashcards.isEmpty else { return }
        let card = flashcards[currentCardIndex]
        let newText = isTermDisplayed ? card.term : card.definition
        cardsView.isUserInteractionEnabled = !(challengeModeSwitch.isOn && isTermDisplayed)
        
        if animated {
            UIView.transition(with: cardsLabel, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.updateLabelText(newText)
            })
        } else {
            self.updateLabelText(newText)
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
        self.flashcards = loadedCards
    }

    private func showSaveConfirmation() {
        let alert = UIAlertController(title: "Save", message: "Save to \(parentSubjectName ?? "Study")?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            self.persistGeneratedCards()
            self.navigationController?.popViewController(animated: true)
        })
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
