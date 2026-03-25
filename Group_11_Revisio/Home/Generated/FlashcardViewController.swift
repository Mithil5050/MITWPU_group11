import UIKit

struct Flashcard {
    let term: String
    let definition: String
    let keyword: String
}

protocol AddFlashcardDelegate: AnyObject {
    func didCreateNewFlashcard(card: Flashcard)
}

class FlashcardViewController: UIViewController, AddFlashcardDelegate, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardLabel: UILabel!
    

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
    

    
    // MARK: - Properties
    var currentTopic: Topic?
    var parentSubjectName: String?
    
    private var backgroundCard1: UIView!
    private var backgroundCard2: UIView!
    
    private var flashcards: [Flashcard] = []
    private var isTermDisplayed = true
    private var currentCardIndex = 0
    
    private var knownCount = 0
    private var unknownCount = 0
    
    private let resultsOverlay = UIView()
    private var initialCardCenter: CGPoint = .zero

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
        
        setupProgrammaticUI()
        setupGesture()
        
        challengeModeSwitch.addTarget(self, action: #selector(toggleChallengeMode), for: .valueChanged)
        challengeTextField.delegate = self
        challengeTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        updateUI(animated: false)
    }
    
    private func setupProgrammaticUI() {

        view.addSubview(challengeModeSwitch)
        view.addSubview(challengeModeLabel)
        view.addSubview(challengeTextField)
        
        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55)
        ])
        
        NSLayoutConstraint.activate([

            challengeModeSwitch.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 40),
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
            // Force term displayed first to start challenge
            isTermDisplayed = true
            updateUI(animated: true)
        } else {
            challengeTextField.resignFirstResponder()
            cardView.isUserInteractionEnabled = true
        }
    }
    
    @objc private func textFieldDidChange() {
        guard challengeModeSwitch.isOn, let text = challengeTextField.text, !flashcards.isEmpty else { return }
        let currentKeyword = flashcards[currentCardIndex].keyword.lowercased()
        if text.lowercased().contains(currentKeyword) || text.lowercased() == currentKeyword {
            challengeModeSuccess()
        }
    }
    
    private func challengeModeSuccess() {
        challengeTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.3) {
            self.cardView.backgroundColor = .systemGreen
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.setupCardView() // revert to blue
            }
            // Auto flip to answer and enable swipe
            self.isTermDisplayed = false
            self.updateUI(animated: true)
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard challengeModeSwitch.isOn, let text = textField.text, !flashcards.isEmpty else { return false }
        
        let currentKeyword = flashcards[currentCardIndex].keyword.lowercased()
        
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
        cardView.layer.add(animation, forKey: "shake")
        
        let originalColor = cardView.backgroundColor
        let originalBorder = cardView.layer.borderColor
        
        UIView.animate(withDuration: 0.1, animations: {
            self.cardView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
            self.cardView.layer.borderColor = UIColor.systemRed.cgColor
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.2, animations: {
                self.cardView.backgroundColor = originalColor
                self.cardView.layer.borderColor = originalBorder
            }, completion: nil)
        }
    }
    
    // ✅ EXTRACT SAVED DATA
    private func unpackFlashcards(from content: String) {
        let lines = content.components(separatedBy: "\n")
        var loaded: [Flashcard] = []
        
        for line in lines where !line.isEmpty {
            let parts = line.components(separatedBy: "|")
            
            if parts.count >= 3 {
                // ✅ SUCCESS: AI provided Term, Definition, and Keyword
                loaded.append(Flashcard(term: parts[0], definition: parts[1], keyword: parts[2]))
            } else if parts.count == 2 {
                // ⚠️ FALLBACK: If AI missed the keyword, use the Term as the keyword
                loaded.append(Flashcard(term: parts[0], definition: parts[1], keyword: parts[0]))
            }
        }
        
        if !loaded.isEmpty {
            self.flashcards = loaded
        }
    }
    
    // MARK: - UI Setup
    private func setupCardView() {
        cardView.backgroundColor = .systemGray6
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
        view.layer.borderWidth = 3.0
        view.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        
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
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        cardView.addGestureRecognizer(pan)
    }
    
    @objc func handleCardTap() {
        guard !flashcards.isEmpty else { return }
        // Cannot flip manually in challenge mode until solved
        if challengeModeSwitch.isOn && isTermDisplayed {
            return
        }
        isTermDisplayed.toggle()
        updateUI(animated: true)
    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard !flashcards.isEmpty else { return }
        
        guard let card = sender.view else { return }
        let translation = sender.translation(in: view)
        
        // Disable swipe if challenge is active and not yet flipped
        if challengeModeSwitch.isOn && isTermDisplayed {
            return
        }
        
        switch sender.state {
        case .began:
            initialCardCenter = card.center
        case .changed:
            let rotation = (translation.x / view.bounds.width) * 0.4
            card.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
                .rotated(by: rotation)
            
            // Neon border glow
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
            self.cardView.transform = CGAffineTransform(translationX: translationX, y: 0).rotated(by: translationX > 0 ? 0.3 : -0.3)
            self.cardView.alpha = 0
            
            self.backgroundCard1.transform = .identity
            self.backgroundCard2.transform = CGAffineTransform(scaleX: 0.96, y: 0.96).translatedBy(x: 0, y: 24)
        }) { _ in
            self.cardView.transform = .identity
            self.cardView.alpha = 1.0
            self.cardView.center = self.initialCardCenter
            
            if self.currentCardIndex < self.flashcards.count - 1 {
                self.currentCardIndex += 1
                self.isTermDisplayed = true
                self.updateUI(animated: false)
                self.resetStackTransforms()
            } else {
                self.cardView.isHidden = true
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
        
        // Setup internal elements
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
        doneButton.setTitle("Close & Save", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        doneButton.backgroundColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.cornerRadius = 12
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(handleSaveWrapper), for: .touchUpInside)
        
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
    
    @objc private func handleSaveWrapper() {
        self.handleSave()
    }

    
    @IBAction func addFlashcardButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "AddCardSegue", sender: self)
    }
    
    // MARK: - Animations
    // MARK: - UI Updates
    func updateUI(animated: Bool = false) {
        // ✅ Safely handle 0 cards state
        guard !flashcards.isEmpty else {
            cardLabel.text = "No flashcards available.\nTap '+' to add one."
            // countLabel removed
            updateStackVisibility()
            return
        }
        
        let card = flashcards[currentCardIndex]
        let text = isTermDisplayed ? card.term : card.definition
        
        // countLabel removed
        
        if challengeModeSwitch.isOn && isTermDisplayed {
            challengeTextField.text = ""
            // DO NOT call becomeFirstResponder() continuously as it breaks the keyboard flow if user closes it
            // Only lock interaction
            cardView.isUserInteractionEnabled = false // Need to type keyword to unlock
        } else {
            cardView.isUserInteractionEnabled = true
        }
        
        if animated {
            UIView.transition(with: cardView, duration: 0.3, options: .transitionFlipFromRight, animations: {
                self.cardLabel.text = text
            }, completion: nil)
        } else {
            self.cardLabel.text = text
        }
        

        
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
        
        // ✅ Updated to include the 3rd component (keyword)
        let updatedText = flashcards.map { "\($0.term)|\($0.definition)|\($0.keyword)" }.joined(separator: "\n")
        
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
