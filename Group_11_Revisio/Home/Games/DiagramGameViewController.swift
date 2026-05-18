import UIKit
import Vision

class DiagramGameViewController: UIViewController {

    // MARK: - 🔌 Storyboard Outlets
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var canvasView: UIView!

    // Connect your 4 buttons from the bottom grid here
    @IBOutlet weak var wordBankCollectionView: UICollectionView!

    // MARK: - Game Variables
    var diagramImageToPlay: UIImage?

    private let diagramImageView = UIImageView()
    private var loadingOverlayView: GameLoadingOverlayView?
    private var targetBoxes: [TargetBoxView] = []
    private var words: [String] = []
    private var hiddenWords: Set<String> = []
    private var selectedWord: String?
    private var score = 0 {
        didSet { scoreLabel.text = "Score: \(score) / \(words.count)" }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        installQuitConfirmation() // ✅ Guard against accidental exits
        setupDiagramImage()
        setupGame()
    }

    private func setupDiagramImage() {
        // Prepare the image view to hold the dynamically selected diagram
        diagramImageView.contentMode = .scaleAspectFit
        let imageToUse = diagramImageToPlay ?? UIImage(named: "plant_cell_demo")
        diagramImageView.image = imageToUse
        diagramImageView.backgroundColor = .clear
        diagramImageView.layer.cornerRadius = 16
        diagramImageView.clipsToBounds = true
        diagramImageView.isUserInteractionEnabled = true
        diagramImageView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.insertSubview(diagramImageView, at: 0)

        // Setup dynamic constraints so diagramImageView perfectly hugs the image's dimensions!
        diagramImageView.leadingAnchor.constraint(greaterThanOrEqualTo: canvasView.leadingAnchor, constant: 16).isActive = true
        diagramImageView.trailingAnchor.constraint(lessThanOrEqualTo: canvasView.trailingAnchor, constant: -16).isActive = true
        diagramImageView.topAnchor.constraint(greaterThanOrEqualTo: canvasView.topAnchor, constant: 16).isActive = true
        diagramImageView.bottomAnchor.constraint(lessThanOrEqualTo: canvasView.bottomAnchor, constant: -16).isActive = true

        diagramImageView.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor).isActive = true
        diagramImageView.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor).isActive = true

        let widthConstraint = diagramImageView.widthAnchor.constraint(equalTo: canvasView.widthAnchor, constant: -32)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true

        let heightConstraint = diagramImageView.heightAnchor.constraint(equalTo: canvasView.heightAnchor, constant: -32)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true

        if let size = imageToUse?.size, size.height > 0 {
            let ratio = size.width / size.height
            diagramImageView.widthAnchor.constraint(equalTo: diagramImageView.heightAnchor, multiplier: ratio).isActive = true
        }
    }

    // MARK: - Setup
    private func setupGame() {
        score = 0
        canvasView.layer.cornerRadius = 16
        canvasView.layer.masksToBounds = true

        // Clear previous target boxes if any
        targetBoxes.forEach { $0.removeFromSuperview() }
        targetBoxes.removeAll()
        selectedWord = nil
        hiddenWords.removeAll()

        // Collection View Setup
        wordBankCollectionView?.delegate = self
        wordBankCollectionView?.dataSource = self
        wordBankCollectionView?.register(WordPillCell.self, forCellWithReuseIdentifier: "WordPillCell")

        if let layout = wordBankCollectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.minimumInteritemSpacing = 12
            layout.minimumLineSpacing = 12
        }

        // Run Apple Vision to extract labels from the diagram image
        showLoadingOverlay()
        extractLabelsFromDiagram()
    }

    // MARK: - Loading Overlay
    private func showLoadingOverlay() {
        let overlay = GameLoadingOverlayView(
            title: "Scanning diagram...",
            subtitle: "AI is identifying labels"
        )
        overlay.show(in: view)
        loadingOverlayView = overlay
    }

    private func hideLoadingOverlay() {
        loadingOverlayView?.hide()
        loadingOverlayView = nil
    }

    private func getCGImageOrientation(_ uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    private func extractLabelsFromDiagram() {
        guard let image = diagramImageView.image else {
            DispatchQueue.main.async { self.showError(message: "No diagram image found in canvas!") }
            return
        }

        let ciImage = image.ciImage
        guard let cgImage = image.cgImage ?? (ciImage != nil ? CIContext().createCGImage(ciImage!, from: ciImage!.extent) : nil) else {
            DispatchQueue.main.async { self.showError(message: "Could not read image byte data.") }
            return
        }

        // Pass orientation so camera uploads don't scan sideways!
        let orientation = getCGImageOrientation(image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async { self?.showError(message: "Apple Vision failed: \(error?.localizedDescription ?? "Unknown")") }
                return
            }

            DispatchQueue.main.async {
                self?.processTextObservations(observations, imageSize: image.size)
            }
        }

        request.recognitionLevel = .accurate

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { self.showError(message: "Vision perform failed: \(error.localizedDescription)") }
            }
        }
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Diagnostic", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func processTextObservations(_ observations: [VNRecognizedTextObservation], imageSize: CGSize) {
        if observations.isEmpty {
            showError(message: "Apple Vision found exactly 0 text labels. Are you sure this diagram contains clear text?")
            return
        }
        var foundWords: [String] = []
        var observationMap: [String: VNRecognizedTextObservation] = [:]
        var seenKeys = Set<String>()

        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = text.lowercased()

            // Strict filtering: skip titles, very short/long, dashes, numbers, watermarks
            guard isValidLabel(text) else { continue }
            // Skip known noise
            if lower.contains("plant cell") || lower.contains("structure") || lower.contains("anatomy") || lower.contains("shutterstock") || lower.contains("dreamstime") || lower.contains("getty") { continue }

            let key = lower
            guard !seenKeys.contains(key) else { continue }
            seenKeys.insert(key)

            foundWords.append(text)
            observationMap[key] = observation
        }

        if foundWords.isEmpty {
            showError(message: "Found text, but it was all filtered out (e.g. titles or short text).")
            return
        }

        Task {
            do {
                let filteredWords = try await AIContentManager.shared.processVisionLabels(words: foundWords)
                // Clean AI-returned words (strip leading "- ", bullets, etc)
                let cleaned = filteredWords.map { cleanLabel($0) }.filter { !$0.isEmpty }
                let unique = Array(NSOrderedSet(array: cleaned)) as! [String]
                await MainActor.run { self.placeTargetBoxes(for: unique, observationMap: observationMap) }
            } catch {
                await MainActor.run { self.placeTargetBoxes(for: foundWords, observationMap: observationMap) }
            }
        }
    }

    // MARK: - Label Validation Helpers
    private func isValidLabel(_ text: String) -> Bool {
        // Reject too short or too long
        guard text.count >= 3 && text.count <= 30 else { return false }
        // Reject if it starts with a number, dash, dot or bullet-like character
        let firstChar = text.unicodeScalars.first!
        if CharacterSet.decimalDigits.contains(firstChar) { return false }
        if "-–—•·".unicodeScalars.contains(firstChar) { return false }
        // Must contain at least one letter
        let hasLetter = text.unicodeScalars.contains { CharacterSet.letters.contains($0) }
        return hasLetter
    }

    private func cleanLabel(_ text: String) -> String {
        // Strip leading markdown bullets, dashes, dots etc
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = ["- ", "• ", "· ", "* ", ". "]
        for prefix in prefixes {
            if cleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func placeTargetBoxes(for wordsList: [String], observationMap: [String: VNRecognizedTextObservation]) {
        var finalWords: [String] = []

        for rawWord in wordsList {
            let searchKey = rawWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            // Try exact match first, then fall back to fuzzy (contains) match
            let observation: VNRecognizedTextObservation?
            if let exact = observationMap[searchKey] {
                observation = exact
            } else {
                // Find the best key in the map that contains or is contained by searchKey
                observation = observationMap.first(where: { mapKey, _ in
                    mapKey.contains(searchKey) || searchKey.contains(mapKey)
                })?.value
            }

            guard let obs = observation else { continue }

            let displayWord = obs.topCandidates(1).first?.string ?? rawWord

            let box = TargetBoxView(correctAnswer: displayWord)
            box.translatesAutoresizingMaskIntoConstraints = false
            diagramImageView.addSubview(box)
            targetBoxes.append(box)

            let tap = UITapGestureRecognizer(target: self, action: #selector(didTapTargetBox(_:)))
            box.addGestureRecognizer(tap)

            let bbox = obs.boundingBox
            let safeCenterXMulti = max(CGFloat(bbox.midX), 0.001)
            let safeCenterYMulti = max(CGFloat(1.0 - bbox.midY), 0.001)

            // Use FIXED height, capped width—no more giant boxes!
            let labelCharCount = CGFloat(max(displayWord.count, 6))
            let estimatedWidth = min(labelCharCount * 9 + 24, 160)

            NSLayoutConstraint.activate([
                box.widthAnchor.constraint(equalToConstant: estimatedWidth),
                box.heightAnchor.constraint(equalToConstant: 28),
                NSLayoutConstraint(item: box, attribute: .centerX, relatedBy: .equal, toItem: diagramImageView, attribute: .trailing, multiplier: safeCenterXMulti, constant: 0),
                NSLayoutConstraint(item: box, attribute: .centerY, relatedBy: .equal, toItem: diagramImageView, attribute: .bottom, multiplier: safeCenterYMulti, constant: 0)
            ])


            finalWords.append(displayWord)
        }

        self.words = finalWords.shuffled()
        score = 0
        wordBankCollectionView?.reloadData()
        hideLoadingOverlay()
    }

    // 2. Tapping an empty box on the canvas
    @objc private func didTapTargetBox(_ gesture: UITapGestureRecognizer) {
        guard let box = gesture.view as? TargetBoxView else { return }
        guard !box.isFilled else { return }
        guard let word = selectedWord else { return }

        // A. Create a "Ghost" pill for the flying animation
        let ghostPill = UILabel()
        ghostPill.text = word
        ghostPill.textColor = .white
        ghostPill.font = .systemFont(ofSize: 13, weight: .regular)
        ghostPill.textAlignment = .center
        ghostPill.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        ghostPill.layer.cornerRadius = 20
        ghostPill.layer.masksToBounds = true
        ghostPill.layer.borderColor = UIColor(white: 1.0, alpha: 0.4).cgColor
        ghostPill.layer.borderWidth = 1

        // B. Start frame is the collection view cell's frame
        var startFrame = CGRect(x: canvasView.bounds.midX - 50, y: canvasView.bounds.maxY, width: 100, height: 44)
        if let index = words.firstIndex(of: word) {
            let indexPath = IndexPath(item: index, section: 0)
            if let cell = wordBankCollectionView?.cellForItem(at: indexPath) {
                let sv = wordBankCollectionView?.superview ?? view!
                startFrame = sv.convert(cell.frame, to: canvasView)
            }
        }
        ghostPill.frame = startFrame
        canvasView.addSubview(ghostPill)

        // C. Hide the real word from collection view visually
        hiddenWords.insert(word)
        selectedWord = nil
        wordBankCollectionView?.reloadData()

        // D. Magically animate the ghost pill flying to the target box
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            ghostPill.frame = box.frame
        }) { _ in
            ghostPill.removeFromSuperview()
            self.validatePlacement(word: word, box: box)
        }
    }

    // 3. Checking if they got it right
    private func validatePlacement(word: String, box: TargetBoxView) {
        if word == box.correctAnswer {
            // Correct! Box turns green
            box.setFilled(isCorrect: true)
            box.setTitle(word)

            score += 1
            if score == words.count {
                showWinAlert()
            }
        } else {
            // Wrong! Flash red, shake, and return button to word bank
            box.shake()
            box.flashRed()

            // Re-appear the block in the word bank cleanly
            hiddenWords.remove(word)
            wordBankCollectionView?.reloadData()
        }
    }

    // MARK: - Storyboard Actions


    private func showWinAlert() {
        let alert = UIAlertController(title: "Level Complete! 🎉", message: "You mastered the Animal Cell.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Finish", style: .default, handler: { _ in
            self.dismiss(animated: true)
        }))
        present(alert, animated: true)
    }
}

// MARK: - Collection View Methods
extension DiagramGameViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WordPillCell", for: indexPath) as? WordPillCell else {
            return UICollectionViewCell()
        }

        let word = words[indexPath.item]
        cell.setWord(word)

        let isSelected = (word == selectedWord)
        cell.setSelectedState(isSelected)

        cell.isHidden = hiddenWords.contains(word)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let word = words[indexPath.item]
        if hiddenWords.contains(word) { return }

        // Toggle selection
        if selectedWord == word {
            selectedWord = nil
        } else {
            selectedWord = word
        }
        collectionView.reloadData()
    }
}

// MARK: - Target Box View (Keep at the bottom)
class TargetBoxView: UIView {
    let correctAnswer: String
    var isFilled = false
    private let titleLabel = UILabel()
    private let dashLayer = CAShapeLayer()

    init(correctAnswer: String) {
        self.correctAnswer = correctAnswer
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        // Rich indigo — looks great over both white and dark diagram backgrounds
        backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.28, alpha: 0.92)
        layer.cornerRadius = 6
        dashLayer.strokeColor = UIColor(red: 0.55, green: 0.65, blue: 1.0, alpha: 0.8).cgColor
        dashLayer.lineWidth = 1.2
        dashLayer.lineDashPattern = [5, 3]
        dashLayer.fillColor = nil
        layer.addSublayer(dashLayer)

        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dashLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 8).cgPath
    }

    func setTitle(_ text: String) { titleLabel.text = text }

    func setFilled(isCorrect: Bool) {
        isFilled = true
        dashLayer.isHidden = true
        backgroundColor = isCorrect ? UIColor(white: 1.0, alpha: 0.1) : .systemRed
        if isCorrect {
            layer.borderWidth = 1
            layer.borderColor = UIColor(white: 1.0, alpha: 0.4).cgColor
        }
    }

    func flashRed() {
        let oldColor = backgroundColor
        UIView.animate(withDuration: 0.15, animations: { self.backgroundColor = UIColor.systemRed.withAlphaComponent(0.4) }) { _ in
            UIView.animate(withDuration: 0.15) { self.backgroundColor = oldColor }
        }
    }

    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-10, 10, -8, 8, -5, 5, 0]
        layer.add(animation, forKey: "shake")
    }
}

// MARK: - Word Pill Cell
class WordPillCell: UICollectionViewCell {
    let titleLabel = UILabel()
    private var isSetup = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        guard !isSetup else { return }
        isSetup = true

        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 20
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor(white: 1.0, alpha: 0.3).cgColor

        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attr = super.preferredLayoutAttributesFitting(layoutAttributes)
        let size = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        attr.frame.size.width = size.width
        attr.frame.size.height = 40
        return attr
    }

    func setWord(_ word: String) {
        titleLabel.text = word
    }

    func setSelectedState(_ isSelected: Bool) {
        contentView.layer.borderColor = isSelected ? UIColor.white.cgColor : UIColor(white: 1.0, alpha: 0.3).cgColor
        contentView.backgroundColor = isSelected ? UIColor(white: 1.0, alpha: 0.1) : .clear
    }
}
