import UIKit

// MARK: - Data Model
struct Flashcard {
    let term: String
    let definition: String
    let keyword: String
}

protocol AddFlashcardDelegate: AnyObject {
    func didCreateNewFlashcard(card: Flashcard)
}

// MARK: - Reusable Card Slot View
private class CardSlotView: UIView {

    let textLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 24, weight: .medium)
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
        l.letterSpacing(2)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = UIColor(red: 0.13, green: 0.15, blue: 0.24, alpha: 1.0)
        layer.cornerRadius = 20
        layer.borderWidth = 2.8
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
        let purple = UIColor.systemPurple.withAlphaComponent(0.8)
        let color = isTerm ? blue : purple
        sideLabel.textColor = color
        layer.borderColor = color.cgColor
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = 0.55
        layer.shadowOffset = .zero
        layer.shadowRadius = 8
    }

    func resetBorderToTerm() {
        layer.borderColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
        layer.shadowColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0).cgColor
    }
}

private extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        // swift won't allow stored props in extension, just a no-op helper tag
    }
}

// MARK: - FlashcardViewController (Home)
class FlashcardViewController: UIViewController, AddFlashcardDelegate, UITextFieldDelegate {

    // MARK: - Storyboard Outlets (hidden, replaced by carousel)
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardLabel: UILabel!

    // MARK: - Carousel Views
    private let carouselContainer = UIView()
    private let prevCard  = CardSlotView()
    private let frontCard = CardSlotView()
    private let nextCard  = CardSlotView()

    // MARK: - Supporting UI
    private let countLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.lightGray
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textAlignment = .center
        l.layer.zPosition = 1000 // Ensure it renders above cards that overflow the container
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
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
        tf.layer.zPosition = 200
        return tf
    }()

    // MARK: - Properties
    var currentTopic: Topic?
    var parentSubjectName: String?

    private var flashcards: [Flashcard] = []
    private var fullDeck: [Flashcard] = []
    private var originalDeckSize = 0
    private var globalCardStates: [String: Bool] = [:] // true = known, false = review
    private var reviewCounts: [String: Int] = [:]
    private var isTermDisplayed = true
    private var isChallengePhase = false
    private var currentCardIndex = 0
    private var isAnimating = false
    private var lastLayoutSize: CGSize = .zero

    // Carousel slot configs
    private struct SlotCfg {
        let yOff: CGFloat; let scale: CGFloat; let alpha: CGFloat; let xRotDeg: CGFloat; let zOff: CGFloat
    }
    private let cfgPrev  = SlotCfg(yOff: -140, scale: 0.92, alpha: 0.45, xRotDeg: 0, zOff: -80)
    private let cfgFront = SlotCfg(yOff:    0, scale: 1.00, alpha: 1.00, xRotDeg: 0, zOff: 100)
    private let cfgNext  = SlotCfg(yOff:  140, scale: 0.92, alpha: 0.45, xRotDeg: 0, zOff: -80)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        cardView?.isHidden = true
        cardLabel?.isHidden = true

        if let name = currentTopic?.name { self.title = name }

        if let body = currentTopic?.largeContentBody, !body.isEmpty {
            unpackFlashcards(from: body)
        } else if let fallback = currentTopic?.notesContent, !fallback.isEmpty {
            unpackFlashcards(from: fallback)
        }

        setupCarouselContainer()
        setupSupportingUI()
        setupGestures()

        challengeTextField.delegate = self
        challengeTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addFlashcardTapped)),
            UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(showInstructions))
        ]
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = carouselContainer.bounds.size
        guard size != lastLayoutSize, size.width > 0 else { return }
        lastLayoutSize = size
        layoutCardFrames()
        refreshCarousel(animated: false)
    }

    // MARK: - Carousel Setup
    private func setupCarouselContainer() {
        carouselContainer.clipsToBounds = false
        carouselContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(carouselContainer)
        NSLayoutConstraint.activate([
            carouselContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            carouselContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            carouselContainer.widthAnchor.constraint(equalTo: view.widthAnchor),
            carouselContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.62)
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
        let h = carouselContainer.bounds.height * 0.68
        let cx = carouselContainer.bounds.midX
        let cy = carouselContainer.bounds.midY

        prevCard.bounds  = CGRect(origin: .zero, size: CGSize(width: w, height: h))
        frontCard.bounds = CGRect(origin: .zero, size: CGSize(width: w, height: h))
        nextCard.bounds  = CGRect(origin: .zero, size: CGSize(width: w, height: h))

        prevCard.center  = CGPoint(x: cx, y: cy)
        frontCard.center = CGPoint(x: cx, y: cy)
        nextCard.center  = CGPoint(x: cx, y: cy)
    }

    // MARK: - Transform Helpers
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
        } else {
            block()
        }
    }

    // MARK: - Content Refresh
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
        frontCard.layer.borderWidth = 2.8

        if currentCardIndex > 0 {
            prevCard.configure(isTerm: true, text: flashcards[currentCardIndex - 1].term)
        }
        if currentCardIndex < flashcards.count - 1 {
            nextCard.configure(isTerm: true, text: flashcards[currentCardIndex + 1].term)
        }

        // Strip decoration from background cards but keep fill visible
        for bg in [prevCard, nextCard] {
            bg.layer.borderWidth = 0
            bg.layer.shadowOpacity = 0
            bg.sideLabel.isHidden = true
            bg.backgroundColor = UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1.0)
        }
        // Ensure front card is solid
        frontCard.backgroundColor = UIColor(red: 0.13, green: 0.15, blue: 0.24, alpha: 1.0)

        countLabel.text = "\(currentCardIndex + 1) / \(flashcards.count)"
        frontCard.isUserInteractionEnabled = !(isChallengePhase && isTermDisplayed)
        applySlotTransforms(animated: animated)
    }

    // MARK: - Gesture Setup
    private func setupGestures() {
        frontCard.isUserInteractionEnabled = true
        frontCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        frontCard.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
    }

    @objc private func handleTap() {
        guard !flashcards.isEmpty else { return }
        if isChallengePhase && isTermDisplayed { return }
        isTermDisplayed.toggle()
        let card = flashcards[currentCardIndex]
        let flipDir: UIView.AnimationOptions = isTermDisplayed ? .transitionFlipFromLeft : .transitionFlipFromRight
        UIView.transition(with: frontCard, duration: 0.5, options: flipDir, animations: {
            self.frontCard.configure(isTerm: self.isTermDisplayed,
                                     text: self.isTermDisplayed ? card.term : card.definition)
            self.frontCard.layer.borderWidth = 2.8
        })
        // Re-strip background cards
        for bg in [prevCard, nextCard] {
            bg.layer.borderWidth = 0
            bg.layer.shadowOpacity = 0
            bg.sideLabel.isHidden = true
        }
    }

    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        guard !flashcards.isEmpty, !isAnimating else { return }
        if isChallengePhase && isTermDisplayed { return }

        let tx = sender.translation(in: view)
        let vel = sender.velocity(in: view)
        let isVertical = abs(tx.y) > abs(tx.x)

        switch sender.state {
        case .changed:
            if isVertical {
                // Follow finger vertically with mild resistance
                var t = CATransform3DIdentity; t.m34 = -1.0 / 900.0
                let drag = tx.y * 0.55
                t = CATransform3DTranslate(t, 0, drag, 0)
                let scaleDown = max(0.88, 1.0 - abs(drag) / 800)
                t = CATransform3DScale(t, scaleDown, scaleDown, 1)
                frontCard.layer.transform = t

                // Peek adjacent card
                let progress = min(abs(tx.y) / 200, 1.0)
                if tx.y < 0 && currentCardIndex < flashcards.count - 1 {
                    // Going up (next): nextCard peeks up
                    var nt = makeTransform(cfgNext)
                    nt = CATransform3DTranslate(nt, 0, -cfgNext.yOff * progress * 0.4, 0)
                    nextCard.layer.transform = nt
                    nextCard.alpha = cfgNext.alpha + (1.0 - cfgNext.alpha) * progress * 0.6
                } else if tx.y > 0 && currentCardIndex > 0 {
                    // Going down (prev): prevCard peeks down
                    var pt = makeTransform(cfgPrev)
                    pt = CATransform3DTranslate(pt, 0, -cfgPrev.yOff * progress * 0.4, 0)
                    prevCard.layer.transform = pt
                    prevCard.alpha = cfgPrev.alpha + (1.0 - cfgPrev.alpha) * progress * 0.6
                }
            } else {
                // Horizontal: follow with z-rotation
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
                } else {
                    frontCard.resetBorderToTerm()
                }
            }

        case .ended, .cancelled:
            let threshold: CGFloat = 110
            if isVertical {
                if tx.y < -threshold || vel.y < -700 {
                    rolodexForward()
                } else if tx.y > threshold || vel.y > 700 {
                    rolodexBackward()
                } else {
                    snapBack()
                }
            } else {
                if tx.x > threshold || vel.x > 700 {
                    animateKnown()
                } else if tx.x < -threshold || vel.x < -700 {
                    animateReview()
                } else {
                    snapBack()
                }
            }

        default: break
        }
    }

    private func snapBack() {
        UIView.animate(withDuration: 0.38, delay: 0,
                       usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5,
                       options: .curveEaseOut) {
            self.applySlotTransforms(animated: false)
            self.frontCard.resetBorderToTerm()
        }
    }

    // MARK: - Rolodex Navigation
    private func rolodexForward() {
        guard currentCardIndex < flashcards.count - 1 else { snapBack(); return }
        isAnimating = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        UIView.animate(withDuration: 0.38, delay: 0, options: .curveEaseIn, animations: {
            // Front exits upward
            var t = CATransform3DIdentity; t.m34 = -1.0 / 900.0
            t = CATransform3DTranslate(t, 0, -self.view.bounds.height * 0.38, 0)
            t = CATransform3DRotate(t, 18 * .pi / 180, 1, 0, 0)
            t = CATransform3DScale(t, 0.62, 0.62, 1)
            self.frontCard.layer.transform = t
            self.frontCard.alpha = 0
            // Next card rises to center
            self.nextCard.layer.transform = CATransform3DIdentity
            self.nextCard.alpha = 1.0
        }) { _ in
            self.currentCardIndex += 1
            self.isTermDisplayed = true
            self.refreshCarousel(animated: false)

            if self.currentCardIndex < self.flashcards.count - 1 {
                // Pre-stage new next card below and animate in
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
            // Front exits downward
            var t = CATransform3DIdentity; t.m34 = -1.0 / 900.0
            t = CATransform3DTranslate(t, 0, self.view.bounds.height * 0.38, 0)
            t = CATransform3DRotate(t, -18 * .pi / 180, 1, 0, 0)
            t = CATransform3DScale(t, 0.62, 0.62, 1)
            self.frontCard.layer.transform = t
            self.frontCard.alpha = 0
            // Prev card drops to center
            self.prevCard.layer.transform = CATransform3DIdentity
            self.prevCard.alpha = 1.0
        }) { _ in
            self.currentCardIndex -= 1
            self.isTermDisplayed = true
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

    // MARK: - Known / Review
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
            isTermDisplayed = true
            refreshCarousel(animated: false)
            // Animate new front card in from below
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
            // End of round
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
                    self.isTermDisplayed = true
                    self.frontCard.isHidden = false
                    self.refreshCarousel(animated: true)
                })
                self.present(alert, animated: true)
            }
        }
    }

    // MARK: - Challenge Mode
    @objc private func textFieldDidChange() {
        guard isChallengePhase, let text = challengeTextField.text, !flashcards.isEmpty else { return }
        let kw = flashcards[currentCardIndex].keyword.lowercased()
        if text.lowercased().contains(kw) { challengeModeSuccess() }
    }

    private func challengeModeSuccess() {
        challengeTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.25, animations: {
            self.frontCard.backgroundColor = .systemGreen
        }, completion: { _ in
            UIView.animate(withDuration: 0.25) { self.frontCard.backgroundColor = .clear }
            self.isTermDisplayed = false
            self.refreshCarousel(animated: true)
        })
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard isChallengePhase, let text = textField.text, !flashcards.isEmpty else { return false }
        let kw = flashcards[currentCardIndex].keyword.lowercased()
        if text.lowercased().contains(kw) { challengeModeSuccess(); return true }
        shakeCard(); return false
    }

    private func shakeCard() {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.duration = 0.4
        anim.values = [-10, 10, -10, 10, -5, 5, -2, 2, 0] as [CGFloat]
        frontCard.layer.add(anim, forKey: "shake")
        UIView.animate(withDuration: 0.1, animations: {
            self.frontCard.layer.borderColor = UIColor.systemRed.cgColor
        }) { _ in UIView.animate(withDuration: 0.3, delay: 0.2) { self.frontCard.resetBorderToTerm() } }
    }

    // MARK: - Supporting UI
    private func setupSupportingUI() {
        view.addSubview(countLabel)
        view.addSubview(challengeTextField)
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: carouselContainer.bottomAnchor, constant: 36),
            countLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            challengeTextField.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 16),
            challengeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            challengeTextField.widthAnchor.constraint(equalToConstant: 250),
            challengeTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Keyboard
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let kbFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let tfBottom = challengeTextField.frame.maxY
        let offset = tfBottom - (view.frame.height - kbFrame.height)
        if offset > 0 {
            UIView.animate(withDuration: 0.3) {
                self.challengeTextField.transform = CGAffineTransform(translationX: 0, y: -(offset + 20))
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) { self.challengeTextField.transform = .identity }
    }

    // MARK: - Misc
    @objc private func showInstructions() {
        let alert = UIAlertController(title: "How to use Flashcards",
            message: "• Tap card to flip Term ↔ Definition\n• Swipe Up → Next card\n• Swipe Down → Previous card\n• Swipe Right → I Know It ✅\n• Swipe Left → Review Later ❌",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        present(alert, animated: true)
    }

    @objc private func addFlashcardTapped() {
        performSegue(withIdentifier: "AddCardSegue", sender: self)
    }

    // MARK: - Data
    private func unpackFlashcards(from content: String) {
        var loaded: [Flashcard] = []
        for line in content.components(separatedBy: "\n") where !line.isEmpty {
            let p = line.components(separatedBy: "|")
            if p.count >= 3 { loaded.append(Flashcard(term: p[0], definition: p[1], keyword: p[2])) }
            else if p.count == 2 { loaded.append(Flashcard(term: p[0], definition: p[1], keyword: p[0])) }
        }
        if !loaded.isEmpty {
            flashcards = loaded
            fullDeck = loaded
            originalDeckSize = loaded.count
        }
    }

    private func showResultsScreen() {
        let sb = UIStoryboard(name: "Home", bundle: nil)
        if let vc = sb.instantiateViewController(withIdentifier: "QuizResultsViewController") as? QuizResultsViewController {
            vc.isFlashcardMode = true
            let kCount = globalCardStates.values.filter { $0 == true }.count
            vc.knownCount = originalDeckSize
            vc.unknownCount = 0
            vc.weakestTerm = reviewCounts.max(by: { $0.value < $1.value })?.key
            
            vc.onChallengeMode = { [weak self] in self?.didSelectChallengeMode() }
            vc.onSaveAndExit = { [weak self] in self?.didSelectSaveAndExit() }
            
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true)
        }
    }

    func handleSave() {
        let folder = parentSubjectName ?? "Study"
        let alert = UIAlertController(
            title: "Save Session?",
            message: "Your progress will be saved to '\(folder)'.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }
            ProgressDataManager.shared.logSession(
                minutes: Double(self.flashcards.count) * 0.5,
                category: "Study"
            )
            // Navigate straight back — no second popup
            if let nav = self.navigationController {
                nav.popToRootViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddCardSegue" {
            let dest: AddFlashcardViewController?
            if let nav = segue.destination as? UINavigationController {
                dest = nav.topViewController as? AddFlashcardViewController
            } else { dest = segue.destination as? AddFlashcardViewController }
            dest?.delegate = self
        }
    }

    func didCreateNewFlashcard(card: Flashcard) {
        ProgressDataManager.shared.totalFlashcardsViewed += 1
        flashcards.append(card)
        fullDeck.append(card)
        originalDeckSize += 1
        let updated = flashcards.map { "\($0.term)|\($0.definition)|\($0.keyword)" }.joined(separator: "\n")
        currentTopic?.largeContentBody = updated
        if let s = parentSubjectName, let t = currentTopic?.name {
            DataManager.shared.updateTopicContent(subject: s, topicName: t, newText: updated, type: "Flashcards")
        }
        currentCardIndex = flashcards.count - 1
        isTermDisplayed = true
        refreshCarousel(animated: true)
    }
}

// MARK: - Results Delegate + Protocol
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
        titleLabel.textColor = .white; titleLabel.textAlignment = .center

        let knownLabel = UILabel()
        knownLabel.text = "✅ Known: \(knownCount)"
        knownLabel.font = .systemFont(ofSize: 20, weight: .semibold); knownLabel.textColor = .systemGreen

        let unknownLabel = UILabel()
        unknownLabel.text = "❌ Need Review: \(unknownCount)"
        unknownLabel.font = .systemFont(ofSize: 20, weight: .semibold); unknownLabel.textColor = .systemRed

        let challengeBtn = makeButton(title: "Enter Challenge Mode", color: UIColor(red: 0.86, green: 0.24, blue: 0.96, alpha: 1))
        challengeBtn.addTarget(self, action: #selector(challengeTapped), for: .touchUpInside)

        let saveBtn = makeButton(title: "Save & Exit", color: UIColor(red: 0, green: 0.55, blue: 0.98, alpha: 1))
        saveBtn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, knownLabel, unknownLabel, challengeBtn, saveBtn])
        stack.axis = .vertical; stack.spacing = 24; stack.alignment = .center
        stack.setCustomSpacing(40, after: unknownLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            challengeBtn.widthAnchor.constraint(equalToConstant: 280), challengeBtn.heightAnchor.constraint(equalToConstant: 54),
            saveBtn.widthAnchor.constraint(equalToConstant: 280), saveBtn.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func makeButton(title: String, color: UIColor) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.backgroundColor = color; b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 14
        return b
    }

    @objc private func challengeTapped() { dismiss(animated: true) { self.delegate?.didSelectChallengeMode() } }
    @objc private func saveTapped() { dismiss(animated: true) { self.delegate?.didSelectSaveAndExit() } }
}

// MARK: - Challenge & Save Extension
extension FlashcardViewController: HomeFlashcardResultsDelegate {
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
        isTermDisplayed = true
        refreshCarousel(animated: false)
        challengeTextField.becomeFirstResponder()
    }

    func didSelectSaveAndExit() { handleSave() }
}
