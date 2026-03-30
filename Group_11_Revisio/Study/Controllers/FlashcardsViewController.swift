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
        tf.layer.zPosition = 101
        return tf
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
    private var isChallengePhase = false
    private var currentCardIndex = 0
    
    private var knownCount = 0
    private var unknownCount = 0

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
        
        challengeTextField.delegate = self
        challengeTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        updateCardContent(animated: false)
        
        let infoBtn = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(showSwipeInstructions))
        let addBtn = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addFlashcardButtonTapped(_:)))
        navigationItem.rightBarButtonItems = [addBtn, infoBtn]
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let originalFrame = self.challengeTextField.frame.applying(self.challengeTextField.transform.inverted())
            let textFieldBottom = originalFrame.maxY
            let offset = textFieldBottom - (self.view.frame.height - keyboardSize.height)
            if offset > 0 {
                UIView.animate(withDuration: 0.3) {
                    self.challengeTextField.transform = CGAffineTransform(translationX: 0, y: -(offset + 20))
                }
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.challengeTextField.transform = .identity
        }
    }

    @objc private func showSwipeInstructions() {
        let alert = UIAlertController(
            title: "How to use Flashcards",
            message: "• Tap the card to flip between Term and Definition.\n• Swipe Left to go to the Next card.\n• Swipe Right to go to the Previous card.\n• Swipe Up when you Know the card.\n• Swipe Down if you need to Review it.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it!", style: .default, handler: nil))
        present(alert, animated: true)
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
        view.addSubview(challengeTextField)
        view.addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: cardsView.bottomAnchor, constant: 80),
            countLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cardsView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55),
            challengeTextField.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 30),
            challengeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            challengeTextField.widthAnchor.constraint(equalToConstant: 250),
            challengeTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    
    @objc private func textFieldDidChange() {
        guard isChallengePhase, let text = challengeTextField.text?.trimmingCharacters(in: .whitespaces), !flashcards.isEmpty else { return }
        
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
        if isChallengePhase && isTermDisplayed {
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
        cardsView.layer.shadowColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        cardsView.layer.shadowOpacity = 0.8
        cardsView.layer.shadowOffset = .zero
        cardsView.layer.shadowRadius = 15
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
        v.layer.masksToBounds = false
        v.layer.shadowColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        v.layer.shadowOpacity = 0.8
        v.layer.shadowOffset = .zero
        v.layer.shadowRadius = 15
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
        if isChallengePhase && isTermDisplayed { return }
        
        UIView.transition(with: cardsView, duration: 0.5, options: isTermDisplayed ? .transitionFlipFromRight : .transitionFlipFromLeft, animations: {
            let card = self.flashcards[self.currentCardIndex]
            self.updateLabelText(self.isTermDisplayed ? card.definition : card.term)
        }, completion: { _ in
            self.isTermDisplayed.toggle()
        })
    }

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard !flashcards.isEmpty, let card = sender.view else { return }
        if isChallengePhase && isTermDisplayed { return }
        
        let translation = sender.translation(in: view)
        switch sender.state {
        case .began: initialCardCenter = card.center
        case .changed:
            let rotation = (translation.x / view.bounds.width) * 0.4
            card.transform = CGAffineTransform(translationX: translation.x, y: translation.y).rotated(by: rotation)
            let isVertical = abs(translation.y) > abs(translation.x)
            if isVertical {
                card.layer.borderColor = translation.y < 0 ? UIColor.systemGreen.cgColor : UIColor.systemRed.cgColor
            } else {
                card.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
            }
        case .ended:
            let isVertical = abs(translation.y) > abs(translation.x)
            if isVertical && abs(translation.y) > 150 {
                translation.y < 0 ? (knownCount += 1) : (unknownCount += 1)
                finishSwipe(translationX: 0, translationY: translation.y < 0 ? -view.bounds.height : view.bounds.height, isNext: true)
            } else if !isVertical && abs(translation.x) > 150 {
                if translation.x < 0 {
                    let skippedCard = self.flashcards[self.currentCardIndex]
                    self.flashcards.append(skippedCard)
                    finishSwipe(translationX: -view.bounds.width, translationY: 0, isNext: true)
                } else {
                    if currentCardIndex > 0 {
                        finishSwipe(translationX: view.bounds.width, translationY: 0, isNext: false)
                    } else {
                        snapBack(card: card)
                    }
                }
            } else {
                snapBack(card: card)
            }
        default: break
        }
    }

    private func snapBack(card: UIView) {
        UIView.animate(withDuration: 0.3) {
            card.center = self.initialCardCenter
            card.transform = .identity
            card.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        }
    }

    private func finishSwipe(translationX: CGFloat, translationY: CGFloat, isNext: Bool) {
        UIView.animate(withDuration: 0.3, animations: {
            self.cardsView.transform = CGAffineTransform(translationX: translationX, y: translationY).rotated(by: translationX > 0 ? 0.3 : (translationX < 0 ? -0.3 : 0))
            self.cardsView.alpha = 0
            
            if isNext {
                self.backgroundCard1.transform = .identity
                self.backgroundCard2.transform = CGAffineTransform(scaleX: 0.96, y: 0.96).translatedBy(x: 0, y: 24)
            }
        }) { _ in
            self.cardsView.transform = .identity
            self.cardsView.alpha = 1.0
            self.cardsView.center = self.initialCardCenter
            self.configureCardViewAppearance()
            
            if isNext {
                if self.currentCardIndex < self.flashcards.count - 1 {
                    self.currentCardIndex += 1
                    self.isTermDisplayed = true
                    self.updateCardContent(animated: false)
                    self.resetStackTransforms()
                } else {
                    self.cardsView.isHidden = true
                    self.showResultsScreen()
                }
            } else {
                self.currentCardIndex -= 1
                self.isTermDisplayed = true
                self.updateCardContent(animated: false)
                self.resetStackTransforms()
            }
        }
    }

    private func showResultsScreen() {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        if let resultsVC = storyboard.instantiateViewController(withIdentifier: "QuizResultsViewController") as? QuizResultsViewController {
            resultsVC.isFlashcardMode = true
            resultsVC.knownCount = knownCount
            resultsVC.unknownCount = unknownCount
            resultsVC.onChallengeMode = { [weak self] in
                self?.didSelectChallengeMode()
            }
            resultsVC.onSaveAndExit = { [weak self] in
                self?.didSelectSaveAndExit()
            }
            let nav = UINavigationController(rootViewController: resultsVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
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
        cardsView.isUserInteractionEnabled = !(isChallengePhase && isTermDisplayed)
        
        countLabel.text = "\(currentCardIndex + 1) / \(flashcards.count)"
        
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

protocol FlashcardResultsDelegate: AnyObject {
    func didSelectChallengeMode()
    func didSelectSaveAndExit()
}

class FlashcardResultsViewController: UIViewController {
    var knownCount = 0
    var unknownCount = 0
    weak var delegate: FlashcardResultsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        let titleLabel = UILabel()
        titleLabel.text = "Study Complete! 🎉"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        
        let knownLabel = UILabel()
        knownLabel.text = "✅ Known: \(knownCount)"
        knownLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        knownLabel.textColor = .systemGreen
        
        let unknownLabel = UILabel()
        unknownLabel.text = "❌ Need Review: \(unknownCount)"
        unknownLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        unknownLabel.textColor = .systemRed
        
        let challengeBtn = UIButton(type: .system)
        challengeBtn.setTitle("Enter Challenge Mode", for: .normal)
        challengeBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        challengeBtn.backgroundColor = UIColor(red: 0.86, green: 0.24, blue: 0.96, alpha: 1.0)
        challengeBtn.setTitleColor(.white, for: .normal)
        challengeBtn.layer.cornerRadius = 14
        challengeBtn.addTarget(self, action: #selector(challengeTapped), for: .touchUpInside)
        
        let saveBtn = UIButton(type: .system)
        saveBtn.setTitle("Save & Exit", for: .normal)
        saveBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        saveBtn.backgroundColor = UIColor(red: 0.0, green: 0.55, blue: 0.98, alpha: 1.0)
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.layer.cornerRadius = 14
        saveBtn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, knownLabel, unknownLabel, challengeBtn, saveBtn])
        stack.axis = .vertical
        stack.spacing = 24
        stack.setCustomSpacing(40, after: unknownLabel)
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            challengeBtn.widthAnchor.constraint(equalToConstant: 280),
            challengeBtn.heightAnchor.constraint(equalToConstant: 54),
            saveBtn.widthAnchor.constraint(equalToConstant: 280),
            saveBtn.heightAnchor.constraint(equalToConstant: 54)
        ])
    }
    
    @objc private func challengeTapped() {
        dismiss(animated: true) {
            self.delegate?.didSelectChallengeMode()
        }
    }
    
    @objc private func saveTapped() {
        dismiss(animated: true) {
            self.delegate?.didSelectSaveAndExit()
        }
    }
}

extension FlashcardsViewController: FlashcardResultsDelegate {
    func didSelectChallengeMode() {
        isChallengePhase = true
        let numCards = min(Int.random(in: 5...7), self.flashcards.count)
        guard numCards > 0 else { return }
        self.flashcards = Array(self.flashcards.shuffled().prefix(numCards))
        self.currentCardIndex = 0
        
        self.cardsView.isHidden = false
        self.challengeTextField.isHidden = false
        self.challengeTextField.text = ""
        self.isTermDisplayed = true
        self.updateCardContent(animated: false)
        self.resetStackTransforms()
        self.challengeTextField.becomeFirstResponder()
    }
    
    func didSelectSaveAndExit() {
        handleDone()
    }
}
