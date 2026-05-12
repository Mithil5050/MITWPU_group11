import UIKit
import Foundation

struct Flashcards: Codable {
    let term: String
    let definition: String
    let keyword: String
}

protocol AddFlashcardsDelegate: AnyObject {
    func didCreateNewFlashcard(card: Flashcard)
}

private class StudyCardSlotView: UIView {

    let textLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let sideLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .bold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = UIColor(red: 0.13, green: 0.15, blue: 0.24, alpha: 1.0)
        
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.16, green: 0.18, blue: 0.28, alpha: 1.0).cgColor,
            UIColor(red: 0.11, green: 0.13, blue: 0.20, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 20
        gradient.frame = bounds
        layer.insertSublayer(gradient, at: 0)
        
        layer.cornerRadius = 20
        layer.borderWidth = 3.0
        layer.masksToBounds = false
        addSubview(textLabel)
        addSubview(sideLabel)
        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            sideLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            sideLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    func configure(isTerm: Bool, text: String) {
        textLabel.text = text
        sideLabel.text = isTerm ? "TERM" : "DEFINITION"
        sideLabel.isHidden = false
        let blue = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0)
        let purple = UIColor.systemPurple.withAlphaComponent(0.9)
        let color = isTerm ? blue : purple
        sideLabel.textColor = color
        layer.borderColor = color.cgColor
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowOffset = .zero
        layer.shadowRadius = 10
        
        if let grad = layer.sublayers?.first as? CAGradientLayer {
            grad.frame = bounds
        }
    }

    func resetBorder(isTerm: Bool) {
        let blue = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0)
        let purple = UIColor.systemPurple.withAlphaComponent(0.8)
        let color = isTerm ? blue : purple
        layer.borderColor = color.cgColor
        layer.shadowColor = color.cgColor
    }
}

class FlashcardsViewController: UIViewController, AddFlashcardsDelegate, UITextFieldDelegate {

    @IBOutlet weak var cardsView: UIView!
    @IBOutlet weak var cardsLabel: UILabel!

    private let carouselContainer = UIView()
    private let prevCard  = StudyCardSlotView()
    private let frontCard = StudyCardSlotView()
    private let nextCard  = StudyCardSlotView()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.textColor = .lightGray
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textAlignment = .center
        l.layer.zPosition = 1000
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let challengeTextField: UITextField = {
        let tf = UITextField()
        tf.textAlignment = .center
        tf.font = .systemFont(ofSize: 18, weight: .semibold)
        tf.textColor = .white
        tf.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        tf.layer.cornerRadius = 14
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 1.5
        tf.layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.8).cgColor
        
        let placeholderAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.lightGray]
        tf.attributedPlaceholder = NSAttributedString(string: "Type keyword here...", attributes: placeholderAttributes)
        
        tf.isHidden = true
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.layer.zPosition = 200
        return tf
    }()

    var currentTopic: Topic?
    var parentSubjectName: String?
    var isFromGenerationScreen: Bool = false
    var startInChallengeMode: Bool = false

    private var flashcards: [Flashcard] = []
    private var fullDeck: [Flashcard] = []
    private var originalDeckSize = 0
    private var globalCardStates: [String: Bool] = [:]
    private var reviewCounts: [String: Int] = [:]
    private var isTermDisplayed = true
    private var isChallengePhase = false
    private var currentCardIndex = 0
    private var isAnimating = false
    private var isShowingSuccessState = false
    private var lastLayoutSize: CGSize = .zero
    private var sessionStartTime: Date? = Date()

    private struct SlotCfg {
        let yOff: CGFloat; let scale: CGFloat; let alpha: CGFloat; let xRotDeg: CGFloat; let zOff: CGFloat
    }
    private let cfgPrev  = SlotCfg(yOff: -90, scale: 0.92, alpha: 0.45, xRotDeg: 0, zOff: -80)
    private let cfgFront = SlotCfg(yOff:    0, scale: 1.00, alpha: 1.00, xRotDeg: 0, zOff: 100)
    private let cfgNext  = SlotCfg(yOff:   90, scale: 0.92, alpha: 0.45, xRotDeg: 0, zOff: -80)

    override func viewDidLoad() {
        super.viewDidLoad()
        cardsView?.isHidden = true
        cardsLabel?.isHidden = true

        if let name = currentTopic?.name {
            let clean = name
                .replacingOccurrences(of: ".txt", with: "")
                .replacingOccurrences(of: "Note_", with: "")
                .replacingOccurrences(of: "Link_", with: "")
                .replacingOccurrences(of: "_", with: " ")
            // Multi-line title so long names like "Carbohydrates Flashcards" never get truncated
            let titleLabel = UILabel()
            titleLabel.text = clean
            titleLabel.numberOfLines = 2
            titleLabel.textAlignment = .center
            titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
            titleLabel.textColor = .white
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.sizeToFit()
            navigationItem.titleView = titleLabel
        }

        if let body = currentTopic?.largeContentBody, !body.isEmpty {
            unpackFlashcards(from: body)
        } else if let fallback = currentTopic?.notesContent {
            unpackFlashcards(from: fallback)
        }

        if let topic = currentTopic {
            if let savedIndex = topic.currentProgressIndex,
               let total = topic.totalItemsCount,
               savedIndex < total {
                currentCardIndex = savedIndex
            }
            
            isChallengePhase = startInChallengeMode
            if isChallengePhase {
                isTermDisplayed = false
                challengeTextField.isHidden = false
            } else {
                isTermDisplayed = true
                challengeTextField.isHidden = true
            }
        }

        setupCarouselContainer()
        setupSupportingUI()
        setupGestures()

        challengeTextField.delegate = self
        challengeTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addFlashcardButtonTapped(_:))),
            UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(showInstructions))
        ]
        
        let backAction = UIAction { [weak self] _ in
            self?.showExitWarning()
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), primaryAction: backAction)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        if var topic = currentTopic, !flashcards.isEmpty {
            let knownCount = globalCardStates.values.filter { $0 == true }.count
            if knownCount == originalDeckSize {
                topic.currentProgressIndex = originalDeckSize
            } else {
                topic.currentProgressIndex = min(max(knownCount, currentCardIndex), originalDeckSize - 1)
            }
            topic.totalItemsCount = originalDeckSize
            DataManager.shared.updateTopic(subjectName: parentSubjectName ?? "Study", topic: topic)
        }
    }

    private func showExitWarning() {
        let alert = UIAlertController(
            title: "Quit Session?",
            message: "Your progress will be saved automatically. Exit?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { [weak self] _ in
            self?.handleDone()
        })
        present(alert, animated: true)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = carouselContainer.bounds.size
        guard size != lastLayoutSize, size.width > 0 else { return }
        lastLayoutSize = size
        layoutCardFrames()
        refreshCarousel(animated: false)
        
        if startInChallengeMode {
            DispatchQueue.main.async {
                self.didSelectChallengeMode()
            }
        }
    }

    private func setupCarouselContainer() {
        carouselContainer.clipsToBounds = false
        carouselContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(carouselContainer)
        NSLayoutConstraint.activate([
            carouselContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            carouselContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            carouselContainer.widthAnchor.constraint(equalTo: view.widthAnchor),
            carouselContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.40)
        ])
        prevCard.isUserInteractionEnabled = false
        nextCard.isUserInteractionEnabled = false
        prevCard.layer.zPosition  = 1
        nextCard.layer.zPosition  = 1
        frontCard.layer.zPosition = 10
        [prevCard, nextCard, frontCard].forEach { carouselContainer.addSubview($0) }
    }

    private func layoutCardFrames() {
        guard carouselContainer.bounds.width > 0 else { return }
        let w = carouselContainer.bounds.width - 80
        let h = carouselContainer.bounds.height * 0.90
        let cx = carouselContainer.bounds.midX
        let cy = carouselContainer.bounds.midY
        let size = CGSize(width: w, height: h)
        [prevCard, frontCard, nextCard].forEach {
            $0.bounds = CGRect(origin: .zero, size: size)
            $0.center = CGPoint(x: cx, y: cy)
        }
    }

    private func makeTransform(_ cfg: SlotCfg) -> CATransform3D {
        var t = CATransform3DIdentity
        t.m34 = -1.0 / 900.0
        t = CATransform3DTranslate(t, 0, cfg.yOff, cfg.zOff)
        t = CATransform3DRotate(t, cfg.xRotDeg * .pi / 180, 1, 0, 0)
        t = CATransform3DScale(t, cfg.scale, cfg.scale, 1)
        return t
    }

    private func applySlotTransforms(animated: Bool) {
        let hasPrev = currentCardIndex > 0
        let hasNext = currentCardIndex < flashcards.count - 1
        let block: () -> Void = {
            self.prevCard.layer.transform  = self.makeTransform(self.cfgPrev)
            self.prevCard.alpha            = hasPrev ? self.cfgPrev.alpha : 0
            self.frontCard.layer.transform = self.makeTransform(self.cfgFront)
            self.frontCard.alpha           = 1.0
            self.nextCard.layer.transform  = self.makeTransform(self.cfgNext)
            self.nextCard.alpha            = hasNext ? self.cfgNext.alpha : 0
        }
        if animated {
            UIView.animate(withDuration: 0.42, delay: 0,
                           usingSpringWithDamping: 0.84, initialSpringVelocity: 0.4,
                           options: .curveEaseOut, animations: block)
        } else { block() }
    }

    private func refreshCarousel(animated: Bool) {
        guard !flashcards.isEmpty else {
            frontCard.configure(isTerm: true, text: "No flashcards yet.\nTap '+' to add one.")
            frontCard.sideLabel.text = ""
            prevCard.alpha = 0; nextCard.alpha = 0
            countLabel.text = "0 / 0"
            return
        }
        let card = flashcards[currentCardIndex]
        frontCard.configure(isTerm: isTermDisplayed, text: isTermDisplayed ? card.term : card.definition)
        
        if isShowingSuccessState {
            frontCard.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
            frontCard.layer.borderColor = UIColor.systemGreen.cgColor
            frontCard.layer.shadowColor = UIColor.systemGreen.cgColor
        } else {
            frontCard.backgroundColor = UIColor(red: 0.13, green: 0.15, blue: 0.24, alpha: 1.0)
        }
        
        frontCard.layer.borderWidth = 2.8

        if currentCardIndex > 0 {
            prevCard.configure(isTerm: true, text: flashcards[currentCardIndex - 1].term)
        }
        if currentCardIndex < flashcards.count - 1 {
            nextCard.configure(isTerm: true, text: flashcards[currentCardIndex + 1].term)
        }

        for bg in [prevCard, nextCard] {
            bg.layer.borderWidth = 0
            bg.layer.shadowOpacity = 0
            bg.sideLabel.isHidden = true
            bg.backgroundColor = UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1.0)
        }
        frontCard.backgroundColor = UIColor(red: 0.13, green: 0.15, blue: 0.24, alpha: 1.0)

        // Restore cumulative count logic
        let knownBeforeRound = originalDeckSize - flashcards.count
        countLabel.text = "\(knownBeforeRound + currentCardIndex + 1) / \(originalDeckSize)"
        applySlotTransforms(animated: animated)
    }

    private func setupGestures() {
        frontCard.isUserInteractionEnabled = true
        frontCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        frontCard.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if isChallengePhase && !isTermDisplayed {
            shakeCard()
            return
        }
        isTermDisplayed = !isTermDisplayed
        refreshCarousel(animated: true)
    }

    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        guard !flashcards.isEmpty, !isAnimating, !isChallengePhase else { return }

        let tx = sender.translation(in: view)
        let vel = sender.velocity(in: view)
        let isVertical = abs(tx.y) > abs(tx.x)

        switch sender.state {
        case .changed:
            if isVertical {
                var t = CATransform3DIdentity; t.m34 = -1.0 / 900.0
                let drag = tx.y * 0.55
                t = CATransform3DTranslate(t, 0, drag, 0)
                let s = max(0.88, 1.0 - abs(drag) / 800)
                t = CATransform3DScale(t, s, s, 1)
                frontCard.layer.transform = t

                let progress = min(abs(tx.y) / 200, 1.0)
                if tx.y < 0 && currentCardIndex < flashcards.count - 1 {
                    var nt = makeTransform(cfgNext)
                    nt = CATransform3DTranslate(nt, 0, -cfgNext.yOff * progress * 0.4, 0)
                    nextCard.layer.transform = nt
                    nextCard.alpha = cfgNext.alpha + (1.0 - cfgNext.alpha) * progress * 0.6
                } else if tx.y > 0 && currentCardIndex > 0 {
                    var pt = makeTransform(cfgPrev)
                    pt = CATransform3DTranslate(pt, 0, -cfgPrev.yOff * progress * 0.4, 0)
                    prevCard.layer.transform = pt
                    prevCard.alpha = cfgPrev.alpha + (1.0 - cfgPrev.alpha) * progress * 0.6
                }
            } else {
                let rot = (tx.x / view.bounds.width) * 0.28
                frontCard.layer.transform = CATransform3DMakeAffineTransform(
                    CGAffineTransform(translationX: tx.x, y: tx.y * 0.15).rotated(by: rot)
                )
                if tx.x > 40 {
                    frontCard.layer.borderColor = UIColor.systemGreen.cgColor
                    frontCard.layer.shadowColor = UIColor.systemGreen.cgColor
                } else if tx.x < -40 {
                    frontCard.layer.borderColor = UIColor.systemRed.cgColor
                    frontCard.layer.shadowColor = UIColor.systemRed.cgColor
                } else { frontCard.resetBorder(isTerm: isTermDisplayed) }
            }

        case .ended, .cancelled:
            let threshold: CGFloat = 110
            if isVertical {
                if tx.y < -threshold || vel.y < -700       { rolodexForward() }
                else if tx.y > threshold || vel.y > 700    { rolodexBackward() }
                else                                       { snapBack() }
            } else {
                if tx.x > threshold || vel.x > 700         { animateKnown() }
                else if tx.x < -threshold || vel.x < -700  { animateReview() }
                else                                       { snapBack() }
            }
        default: break
        }
    }

    private func snapBack() {
        UIView.animate(withDuration: 0.38, delay: 0,
                       usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5,
                       options: .curveEaseOut) {
            self.applySlotTransforms(animated: false)
            self.frontCard.resetBorder(isTerm: self.isTermDisplayed)
        }
    }

    private func rolodexForward() {
        guard currentCardIndex < flashcards.count - 1 else { snapBack(); return }
        isAnimating = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        UIView.animate(withDuration: 0.38, delay: 0, options: .curveEaseIn, animations: {
            var t = CATransform3DIdentity; t.m34 = -1.0 / 900.0
            t = CATransform3DTranslate(t, 0, -self.view.bounds.height * 0.38, 0)
            t = CATransform3DRotate(t, 18 * .pi / 180, 1, 0, 0)
            t = CATransform3DScale(t, 0.62, 0.62, 1)
            self.frontCard.layer.transform = t
            self.frontCard.alpha = 0
            self.nextCard.layer.transform = CATransform3DIdentity
            self.nextCard.alpha = 1.0
        }) { _ in
            self.currentCardIndex += 1
            self.isTermDisplayed = !self.isChallengePhase
            self.refreshCarousel(animated: false)
            if self.currentCardIndex < self.flashcards.count - 1 {
                var startT = self.makeTransform(self.cfgNext)
                startT = CATransform3DTranslate(startT, 0, 90, 0)
                self.nextCard.alpha = 0
                self.nextCard.layer.transform = startT
                UIView.animate(withDuration: 0.35, delay: 0.05,
                               usingSpringWithDamping: 0.88, initialSpringVelocity: 0.3,
                               options: .curveEaseOut) {
                    self.nextCard.layer.transform = self.makeTransform(self.cfgNext)
                    self.nextCard.alpha = self.cfgNext.alpha
                }
            }
            self.isAnimating = false
        }
    }

    private func rolodexBackward() {
        guard currentCardIndex > 0 else { snapBack(); return }
        isAnimating = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        UIView.animate(withDuration: 0.38, delay: 0, options: .curveEaseIn, animations: {
            var t = CATransform3DIdentity; t.m34 = -1.0 / 900.0
            t = CATransform3DTranslate(t, 0, self.view.bounds.height * 0.38, 0)
            t = CATransform3DRotate(t, -18 * .pi / 180, 1, 0, 0)
            t = CATransform3DScale(t, 0.62, 0.62, 1)
            self.frontCard.layer.transform = t
            self.frontCard.alpha = 0
            self.prevCard.layer.transform = CATransform3DIdentity
            self.prevCard.alpha = 1.0
        }) { _ in
            self.currentCardIndex -= 1
            self.isTermDisplayed = !self.isChallengePhase
            self.refreshCarousel(animated: false)
            if self.currentCardIndex > 0 {
                var startT = self.makeTransform(self.cfgPrev)
                startT = CATransform3DTranslate(startT, 0, -90, 0)
                self.prevCard.alpha = 0
                self.prevCard.layer.transform = startT
                UIView.animate(withDuration: 0.35, delay: 0.05,
                               usingSpringWithDamping: 0.88, initialSpringVelocity: 0.3,
                               options: .curveEaseOut) {
                    self.prevCard.layer.transform = self.makeTransform(self.cfgPrev)
                    self.prevCard.alpha = self.cfgPrev.alpha
                }
            }
            self.isAnimating = false
        }
    }

    private func animateKnown() {
        isAnimating = true
        globalCardStates[flashcards[currentCardIndex].term] = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.animate(withDuration: 0.15) {
            self.frontCard.layer.borderColor = UIColor.systemGreen.cgColor
            self.frontCard.layer.shadowColor = UIColor.systemGreen.cgColor
        }
        UIView.animate(withDuration: 0.38, delay: 0.08, options: .curveEaseIn, animations: {
            let rot = CATransform3DMakeAffineTransform(
                CGAffineTransform(translationX: self.view.bounds.width * 1.1, y: 0).rotated(by: 0.28))
            self.frontCard.layer.transform = rot
            self.frontCard.alpha = 0
        }) { _ in self.advanceAfterSwipe() }
    }

    private func animateReview() {
        isAnimating = true
        globalCardStates[flashcards[currentCardIndex].term] = false
        reviewCounts[flashcards[currentCardIndex].term, default: 0] += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.animate(withDuration: 0.15) {
            self.frontCard.layer.borderColor = UIColor.systemRed.cgColor
            self.frontCard.layer.shadowColor = UIColor.systemRed.cgColor
        }
        UIView.animate(withDuration: 0.38, delay: 0.08, options: .curveEaseIn, animations: {
            let rot = CATransform3DMakeAffineTransform(
                CGAffineTransform(translationX: -self.view.bounds.width * 1.1, y: 0).rotated(by: -0.28))
            self.frontCard.layer.transform = rot
            self.frontCard.alpha = 0
        }) { _ in self.advanceAfterSwipe() }
    }

    private func advanceAfterSwipe() {
        if currentCardIndex < flashcards.count - 1 {
            currentCardIndex += 1
            isTermDisplayed = !isChallengePhase
            refreshCarousel(animated: false)
            var startT = CATransform3DIdentity; startT.m34 = -1.0 / 900.0
            startT = CATransform3DTranslate(startT, 0, 160, 0)
            startT = CATransform3DScale(startT, 0.72, 0.72, 1)
            frontCard.layer.transform = startT
            frontCard.alpha = 0
            UIView.animate(withDuration: 0.45, delay: 0,
                           usingSpringWithDamping: 0.80, initialSpringVelocity: 0.4,
                           options: .curveEaseOut) {
                self.frontCard.layer.transform = CATransform3DIdentity
                self.frontCard.alpha = 1.0
            }
            isAnimating = false
        } else {
            var nextRound: [Flashcard] = []
            for card in flashcards {
                if globalCardStates[card.term] != true {
                    nextRound.append(card)
                }
            }
            
            isAnimating = false
            frontCard.isHidden = true
            
            if nextRound.isEmpty {
                showResultsScreen()
            } else {
                let alert = UIAlertController(title: "Round Complete", message: "You have \(nextRound.count) cards left to review.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
                    self.flashcards = nextRound
                    self.currentCardIndex = 0
                    self.isTermDisplayed = !self.isChallengePhase
                    self.frontCard.isHidden = false
                    self.refreshCarousel(animated: true)
                })
                self.present(alert, animated: true)
            }
        }
    }

    @objc private func textFieldDidChange() {
        guard isChallengePhase, let text = challengeTextField.text?.trimmingCharacters(in: .whitespaces),
              !flashcards.isEmpty else { return }
        let card = flashcards[currentCardIndex]
        let kw = card.keyword.isEmpty ? card.term.lowercased() : card.keyword.lowercased()
        if isAnswerCorrect(text.lowercased(), kw: kw) { challengeModeSuccess() }
    }

    private func isAnswerCorrect(_ input: String, kw: String) -> Bool {
        let input = input.lowercased().trimmingCharacters(in: .whitespaces)
        let target = kw.lowercased().trimmingCharacters(in: .whitespaces)
        if input == target { return true }
        if input == target + "s" || target == input + "s" { return true }
        return false
    }

    private func challengeModeSuccess() {
        let term = flashcards[currentCardIndex].term
        globalCardStates[term] = true
        
        challengeTextField.text = ""
        challengeTextField.resignFirstResponder()
        UISelectionFeedbackGenerator().selectionChanged()
        
        isShowingSuccessState = true
        
        UIView.animate(withDuration: 0.25, animations: {
            self.frontCard.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
            self.frontCard.layer.borderColor = UIColor.systemGreen.cgColor
            self.frontCard.layer.shadowColor = UIColor.systemGreen.cgColor
        }, completion: { _ in
            self.isTermDisplayed = true
            self.refreshCarousel(animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                guard let self = self else { return }
                self.isShowingSuccessState = false
                if self.currentCardIndex < self.flashcards.count - 1 {
                    self.advanceAfterSwipe()
                } else {
                    self.showResultsScreen()
                }
            }
        })
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard isChallengePhase else {
            textField.resignFirstResponder()
            return true
        }
        
        let text = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
        let card = flashcards[currentCardIndex]
        let kw = card.keyword.isEmpty ? card.term.lowercased() : card.keyword.lowercased()
        
        if isAnswerCorrect(text, kw: kw) {
            challengeModeSuccess()
        } else {
            shakeCard()
        }
        
        textField.resignFirstResponder()
        return true
    }

    private func shakeCard() {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.duration = 0.4
        anim.values = [-10, 10, -10, 10, -5, 5, -2, 2, 0] as [CGFloat]
        frontCard.layer.add(anim, forKey: "shake")
        UIView.animate(withDuration: 0.1, animations: {
            self.frontCard.layer.borderColor = UIColor.systemRed.cgColor
        }) { _ in UIView.animate(withDuration: 0.3, delay: 0.2) { self.frontCard.resetBorder(isTerm: self.isTermDisplayed) } }
    }

    private func setupSupportingUI() {
        view.addSubview(countLabel)
        view.addSubview(challengeTextField)
        NSLayoutConstraint.activate([
            challengeTextField.topAnchor.constraint(equalTo: carouselContainer.bottomAnchor, constant: 40),
            challengeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            challengeTextField.widthAnchor.constraint(equalToConstant: 250),
            challengeTextField.heightAnchor.constraint(equalToConstant: 44),
            
            countLabel.topAnchor.constraint(equalTo: challengeTextField.bottomAnchor, constant: 16),
            countLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let kbFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let tfBottom = challengeTextField.frame.maxY
        let offset = tfBottom - (view.frame.height - kbFrame.height)
        if offset > 0 {
            UIView.animate(withDuration: 0.3) {
                let navBarBottom = self.view.safeAreaInsets.top + 44
                let kbTop = self.view.frame.height - kbFrame.height
                
                let reservedHeight: CGFloat = 44 + 30 + 20
                let availableForCard = kbTop - navBarBottom - reservedHeight
                
                let containerHeight = self.carouselContainer.frame.height
                var scale = min(0.85, availableForCard / containerHeight)
                scale = max(0.55, scale)
                
                let currentCenterY = self.carouselContainer.center.y
                let translationY = (navBarBottom + 10) + (containerHeight * scale / 2) - currentCenterY
                
                self.carouselContainer.transform = CGAffineTransform(translationX: 0, y: translationY).scaledBy(x: scale, y: scale)
                
                let visualBottom = currentCenterY + translationY + (containerHeight * scale / 2)
                let tfTargetTop = visualBottom + 30
                
                let tfMove = self.challengeTextField.frame.minY - tfTargetTop
                self.challengeTextField.transform = CGAffineTransform(translationX: 0, y: -tfMove)
                
                self.countLabel.alpha = 0
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.challengeTextField.transform = .identity
            self.carouselContainer.transform = .identity
            self.countLabel.alpha = 1
        }
    }

    @objc private func showInstructions() {
        let items: [(icon: String, text: String)]
        if isChallengePhase {
            items = [
                ("text.cursor", "Read definition & type keyword"),
                ("keyboard", "Press return to check answer"),
                ("checkmark.seal.fill", "Unlock card to advance")
            ]
        } else {
            items = [
                ("hand.tap.fill", "Tap card to flip Term ↔ Definition"),
                ("arrow.up", "Swipe Up for Next card"),
                ("arrow.down", "Swipe Down for Previous card"),
                ("checkmark.circle.fill", "Swipe Right if you Know It"),
                ("xmark.circle.fill", "Swipe Left to Review Later")
            ]
        }
        
        let instructionVC = FlashcardInstructionsViewController()
        instructionVC.instructions = items
        instructionVC.modalPresentationStyle = .overFullScreen
        instructionVC.modalTransitionStyle = .crossDissolve
        present(instructionVC, animated: true)
    }

    @objc func handleDone() {
        if isFromGenerationScreen { showSaveConfirmation() }
        else { navigationController?.popViewController(animated: true) }
    }

    @IBAction func addFlashcardButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "addFlashcard", sender: self)
    }

    private func unpackFlashcards(from content: String) {
        var loaded: [Flashcard] = []
        for line in content.components(separatedBy: "\n") where !line.isEmpty {
            let p = line.components(separatedBy: "|")
            if p.count >= 3 { loaded.append(Flashcard(term: p[0], definition: p[1], keyword: p[2])) }
            else if p.count >= 2 { loaded.append(Flashcard(term: p[0], definition: p[1], keyword: p[0])) }
        }
        self.flashcards = loaded
        self.fullDeck = loaded
        self.originalDeckSize = loaded.count
    }

    private func showResultsScreen() {
        let vc = ChallengeSessionResultsViewController()
        vc.knownCount = originalDeckSize
        vc.totalCount = originalDeckSize
        vc.isChallengeResult = isChallengePhase
        vc.flashcardSummary = self.flashcards.map { ($0.term, $0.definition) }
        
        if let startTime = sessionStartTime {
            vc.sessionDuration = Date().timeIntervalSince(startTime)
        }
        
        vc.onChallengeMode = { [weak self] in self?.didSelectChallengeMode() }
        vc.onSaveAndExit = { [weak self] in self?.didSelectSaveAndExit() }
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addFlashcard" {
            let nav = segue.destination as? UINavigationController
            let dest = (nav?.topViewController as? AddFlashcardsViewController)
                    ?? (segue.destination as? AddFlashcardsViewController)
            dest?.delegate = self
        }
    }

    func didCreateNewFlashcard(card: Flashcard) {
        flashcards.append(card)
        let updated = flashcards.map { "\($0.term)|\($0.definition)|\($0.keyword)" }.joined(separator: "\n")
        currentTopic?.largeContentBody = updated
        if let s = parentSubjectName, let t = currentTopic?.name {
            DataManager.shared.updateTopicContent(subject: s, topicName: t, newText: updated, type: "Flashcards")
        }
        currentCardIndex = flashcards.count - 1
        isTermDisplayed = true
        refreshCarousel(animated: true)
    }

    private func showSaveConfirmation() {
        let alert = UIAlertController(title: "Save",
            message: "Save to \(parentSubjectName ?? "Study")?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            self.persistGeneratedCards()
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func persistGeneratedCards() {
        guard let subject = parentSubjectName, let topic = currentTopic else { return }
        let final = flashcards.map { "\($0.term)|\($0.definition)|\($0.keyword)" }.joined(separator: "\n")
        let toSave = Topic(name: topic.name, lastAccessed: "Just now",
                           materialType: "Flashcards", parentSubjectName: subject,
                           largeContentBody: final)
        DataManager.shared.addTopic(to: subject, topic: toSave)
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

        let titleLabel  = makeLabel("Study Complete! ", size: 32, weight: .bold, color: .white)
        let knownLabel  = makeLabel(" Known: \(knownCount)", size: 20, weight: .semibold, color: .systemGreen)
        let unknownLabel = makeLabel(" Need Review: \(unknownCount)", size: 20, weight: .semibold, color: .systemRed)

        let challengeBtn = makeButton(title: "Enter Challenge Mode",
                                      color: UIColor(red: 0.86, green: 0.24, blue: 0.96, alpha: 1))
        challengeBtn.addTarget(self, action: #selector(challengeTapped), for: .touchUpInside)

        let saveBtn = makeButton(title: "Save & Exit",
                                  color: UIColor(red: 0, green: 0.55, blue: 0.98, alpha: 1))
        saveBtn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, knownLabel, unknownLabel, challengeBtn, saveBtn])
        stack.axis = .vertical; stack.spacing = 24; stack.alignment = .center
        stack.setCustomSpacing(40, after: unknownLabel)
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

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let l = UILabel(); l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = color; l.textAlignment = .center; return l
    }

    private func makeButton(title: String, color: UIColor) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.backgroundColor = color; b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 14; return b
    }

    @objc private func challengeTapped() { dismiss(animated: true) { self.delegate?.didSelectChallengeMode() } }
    @objc private func saveTapped()     { dismiss(animated: true) { self.delegate?.didSelectSaveAndExit() } }
}

extension FlashcardsViewController: FlashcardResultsDelegate {
    func didSelectChallengeMode() {
        isChallengePhase = true
        let n = min(Int.random(in: 5...7), fullDeck.count)
        guard n > 0 else { return }
        flashcards = Array(fullDeck.shuffled().prefix(n))
        globalCardStates.removeAll()
        reviewCounts.removeAll()
        originalDeckSize = flashcards.count
        currentCardIndex = 0
        frontCard.isHidden = false
        challengeTextField.isHidden = false
        challengeTextField.text = ""
        isTermDisplayed = false
        refreshCarousel(animated: false)
        challengeTextField.becomeFirstResponder()
    }

    func didSelectSaveAndExit() { handleDone() }
}


