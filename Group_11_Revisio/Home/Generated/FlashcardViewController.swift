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
    

    
    private let sideLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    var currentTopic: Topic?
    var parentSubjectName: String?
    
    private var flashcards: [Flashcard] = []
    private var isTermDisplayed = true
    private var isChallengePhase = false
    private var currentCardIndex = 0
    
    private var knownCount = 0
    private var unknownCount = 0
    
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
        
        setupProgrammaticUI()
        setupGesture()
        
        challengeTextField.delegate = self
        challengeTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        updateUI(animated: false)
        
        let infoBtn = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(showSwipeInstructions))
        let addBtn = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addFlashcardTapped))
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
            message: "• Tap the card to flip between Term and Definition.\n• Swipe Up to go to the Next card.\n• Swipe Down to go to the Previous card.\n• Swipe Right when you Know the card.\n• Swipe Left if you need to Review it.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it!", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func addFlashcardTapped() {
        performSegue(withIdentifier: "AddCardSegue", sender: self)
    }
    
    private func setupProgrammaticUI() {
        view.addSubview(challengeTextField)
        view.addSubview(countLabel)
        cardView.addSubview(sideLabel)
        
        NSLayoutConstraint.activate([
            sideLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            sideLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            sideLabel.heightAnchor.constraint(equalToConstant: 24),
            sideLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            countLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 80),
            countLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55),
            challengeTextField.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 30),
            challengeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            challengeTextField.widthAnchor.constraint(equalToConstant: 250),
            challengeTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    
    @objc private func textFieldDidChange() {
        guard isChallengePhase, let text = challengeTextField.text, !flashcards.isEmpty else { return }
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
        guard isChallengePhase, let text = textField.text, !flashcards.isEmpty else { return false }
        
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
        cardView.backgroundColor = .clear // Fully transparent hollow card
        styleCard(cardView)
        cardView.layer.zPosition = 100
        
        cardLabel.font = .systemFont(ofSize: 26, weight: .medium)
        cardLabel.textAlignment = .center
        cardLabel.numberOfLines = 0
    }
    
    private func styleCard(_ view: UIView) {
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 3.0
        view.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        view.layer.shadowColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 15
        view.layer.masksToBounds = false
    }
    
    private func alignBackgroundCard(_ bgView: UIView) {
        // Removed
    }
    
    private func resetStackTransforms() {
        cardView.transform = .identity
        cardView.alpha = 1.0
        updateStackVisibility()
    }
    
    private func updateStackVisibility() {
        // Stack removed
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
        if isChallengePhase && isTermDisplayed {
            return
        }
        isTermDisplayed.toggle()
        updateUI(animated: true)
    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard !flashcards.isEmpty else { return }
        guard let card = sender.view else { return }
        
        if isChallengePhase && isTermDisplayed { return }
        
        let translation = sender.translation(in: view)
        switch sender.state {
        case .began:
            initialCardCenter = card.center
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
            card.layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
            
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
            self.cardView.transform = CGAffineTransform(translationX: translationX, y: translationY).rotated(by: translationX > 0 ? 0.3 : (translationX < 0 ? -0.3 : 0))
            self.cardView.alpha = 0
        }) { _ in
            self.cardView.transform = .identity
            self.cardView.alpha = 1.0
            self.cardView.center = self.initialCardCenter
            self.styleCard(self.cardView)
            
            if isNext {
                if self.currentCardIndex < self.flashcards.count - 1 {
                    self.currentCardIndex += 1
                    self.isTermDisplayed = true
                    self.updateUI(animated: false)
                    
                    self.cardView.transform = CGAffineTransform(translationX: 0, y: 200).rotated(by: 0.3)
                    self.cardView.alpha = 0
                    UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.6, options: .curveEaseOut, animations: {
                        self.cardView.transform = .identity
                        self.cardView.alpha = 1.0
                    }, completion: nil)
                    
                } else {
                    self.cardView.isHidden = true
                    self.challengeTextField.isHidden = true
                    self.showResultsScreen()
                }
            } else {
                self.currentCardIndex -= 1
                self.isTermDisplayed = true
                self.updateUI(animated: false)
                
                self.cardView.transform = CGAffineTransform(translationX: 0, y: -200).rotated(by: -0.3)
                self.cardView.alpha = 0
                UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.6, options: .curveEaseOut, animations: {
                        self.cardView.transform = .identity
                        self.cardView.alpha = 1.0
                }, completion: nil)
            }
        }
    }

    // MARK: - Animations
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

    // MARK: - UI Updates
    func updateUI(animated: Bool = false) {
        // ✅ Safely handle 0 cards state
        guard !flashcards.isEmpty else {
            cardLabel.text = "No flashcards available.\nTap '+' to add one."
            return
        }
        
        let card = flashcards[currentCardIndex]
        let text = isTermDisplayed ? card.term : card.definition
        
        // Update header and colors based on Term/Definition
        sideLabel.text = isTermDisplayed ? "TERM" : "DEFINITION"
        sideLabel.textColor = isTermDisplayed ? UIColor.systemBlue : UIColor.systemPurple
        sideLabel.backgroundColor = .clear
        cardView.layer.borderColor = isTermDisplayed ? UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor : UIColor.systemPurple.withAlphaComponent(0.6).cgColor
        
        // countLabel removed
        
        if isChallengePhase && isTermDisplayed {
            challengeTextField.text = ""
            // DO NOT call becomeFirstResponder() continuously as it breaks the keyboard flow if user closes it
            // Only lock interaction
            cardView.isUserInteractionEnabled = false // Need to type keyword to unlock
        } else {
            cardView.isUserInteractionEnabled = true
        }
        
        countLabel.text = "\(currentCardIndex + 1) / \(flashcards.count)"
        
        if animated {
            UIView.transition(with: cardView, duration: 0.3, options: .transitionFlipFromRight, animations: {
                self.cardLabel.text = text
            }, completion: nil)
        } else {
            self.cardLabel.text = text
        }
    }
    
    func handleSave() {
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

protocol HomeFlashcardResultsDelegate: AnyObject {
    func didSelectChallengeMode()
    func didSelectSaveAndExit()
}

class HomeFlashcardResultsViewController: UIViewController {
    var knownCount = 0
    var unknownCount = 0
    weak var delegate: HomeFlashcardResultsDelegate?
    
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

extension FlashcardViewController: HomeFlashcardResultsDelegate {
    func didSelectChallengeMode() {
        isChallengePhase = true
        let numCards = min(Int.random(in: 5...7), self.flashcards.count)
        guard numCards > 0 else { return }
        self.flashcards = Array(self.flashcards.shuffled().prefix(numCards))
        self.currentCardIndex = 0
        
        self.cardView.isHidden = false
        self.challengeTextField.isHidden = false
        self.challengeTextField.text = ""
        self.isTermDisplayed = true
        self.updateUI(animated: false)
        self.resetStackTransforms()
        self.challengeTextField.becomeFirstResponder()
    }
    
    func didSelectSaveAndExit() {
        handleSave()
    }
}
