import UIKit

class DailyChallengeViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var ProfitPoints: UIProgressView!
    @IBOutlet weak var keyboardStack: UIStackView!
    @IBOutlet weak var gridContainer: UIStackView!
    
    // Kept this outlet optional in case you still want the cheat button,
    // otherwise you can disconnect and remove it in Storyboard.
    @IBOutlet weak var revealButton: UIButton!
    
    // MARK: - Properties
    private var tileGrid: [[LetterTileView]] = []
    private var keyStates: [Character: LetterTileView.State] = [:]
    private var isGameOver = false
    
    // 🔥 Data
    private var hints: [String] = [
        "A linear data structure that follows the LIFO (Last-In-First-Out) principle.",
                "Key operations include 'push' to add and 'pop' to remove elements."
    ]
    private let engine = WordleEngine(answer: "stack")
    
    private var revealedPositions: Set<Int> = []
    private var currentHintIndex = 0
    private var revealUsed = false
    private var progressScore: Float = 0.0
    private var currentGuess = ""

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar() // 👈 Adds the Hint button to the top
        buildGrid()
        setupKeyboard()
    }
    
    private func setupUI() {
        title = "Daily Challenge"
        view.backgroundColor = .systemBackground
        
        // Setup Hint Label (Hidden initially)
        hintLabel.alpha = 0
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
        hintLabel.text = "Tap the bulb above for a hint!"
        hintLabel.textColor = .secondaryLabel
        
        // Animate label in
        UIView.animate(withDuration: 0.5, delay: 0.5) {
            self.hintLabel.alpha = 1
        }
        
        ProfitPoints.layer.cornerRadius = 4
        ProfitPoints.clipsToBounds = true
    }

    // MARK: - Navigation Bar Setup
    private func setupNavigationBar() {
        // Create the Lightbulb Button
        let hintBtn = UIBarButtonItem(
            image: UIImage(systemName: "lightbulb.max"), // Bulb Icon
            style: .plain,
            target: self,
            action: #selector(hintTapped)
        )
//        hintBtn.tintColor = .systemYellow
        
        // Add to the right side
        navigationItem.rightBarButtonItem = hintBtn
    }

    // MARK: - Grid Setup
    private func buildGrid() {
        gridContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        gridContainer.axis = .vertical
        gridContainer.spacing = 12
        gridContainer.distribution = .fillEqually

        tileGrid = []

        for _ in 0..<4 {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually

            var tiles: [LetterTileView] = []
            for _ in 0..<5 {
                let tile = LetterTileView()
                tile.translatesAutoresizingMaskIntoConstraints = false
                tile.heightAnchor.constraint(equalToConstant: 50).isActive = true
                row.addArrangedSubview(tile)
                tiles.append(tile)
            }
            gridContainer.addArrangedSubview(row)
            tileGrid.append(tiles)
        }
    }

    // MARK: - Game Logic
    func addLetter(_ letter: Character) {
        guard !isGameOver else { return }
        let row = engine.attempts
        guard let index = (0..<5).first(where: { i in
            let tile = tileGrid[row][i]
            let isEmpty = tile.label.text?.isEmpty ?? true
            let isLocked = revealedPositions.contains(i)
            return isEmpty && !isLocked
        }) else { return }

        tileGrid[row][index].label.text = String(letter).uppercased()
        updateCurrentGuess()
    }

    func removeLetter() {
        guard !isGameOver else { return }
        let row = engine.attempts
        guard let index = (0..<5).reversed().first(where: { i in
            let tile = tileGrid[row][i]
            let isFilled = !(tile.label.text?.isEmpty ?? true)
            let isLocked = revealedPositions.contains(i)
            return isFilled && !isLocked
        }) else { return }

        tileGrid[row][index].label.text = ""
        updateCurrentGuess()
    }

    func submitGuess() {
        guard !isGameOver else { return }
        updateCurrentGuess()
        guard currentGuess.count == 5 else {
            shakeGrid()
            return
        }

        let rowIndex = engine.attempts
        let result = engine.evaluate(currentGuess)

        render(result, row: rowIndex)
        updateKeyboard(with: result)
        updateProgress(from: result)
        
        currentGuess = ""
        revealedPositions.removeAll()

        if result.isCorrect {
            endGame(won: true)
        } else if engine.attempts >= engine.maxAttempts {
            endGame(won: false)
        }
    }
    
    private func updateCurrentGuess() {
        let row = engine.attempts
        var guess = ""
        for tile in tileGrid[row] {
            if let text = tile.label.text, !text.isEmpty {
                guess.append(text.lowercased())
            }
        }
        currentGuess = guess
    }

    // MARK: - Actions
    @objc func hintTapped() {
        guard currentHintIndex < hints.count else {
            let alert = UIAlertController(title: "No more hints!", message: "You're on your own now.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let newHint = hints[currentHintIndex]
        currentHintIndex += 1
        
        // Update the Hint Label on screen
        slideHintText(newHint)
        
        incrementProgress(by: -0.05) // Penalty
    }
    
    // (Optional: Keep or remove based on storyboard cleanup)
    @IBAction func revealAlphabetTapped(_ sender: UIButton) {
        guard !isGameOver, !revealUsed else { return }
        
        let row = engine.attempts
        let answerChars = Array(engine.revealedAnswer.uppercased())
        
        let eligibleIndices = (0..<5).filter { index in
            let tile = tileGrid[row][index]
            guard tile.label.text?.isEmpty ?? true else { return false }
            let correctChar = answerChars[index]
            if keyStates[Character(correctChar.lowercased())] == .correct { return false }
            if revealedPositions.contains(index) { return false }
            return true
        }

        guard let index = eligibleIndices.randomElement() else { return }

        revealUsed = true
        // Disable button if it exists
        if let btn = revealButton {
            btn.isEnabled = false
            btn.alpha = 0.5
        }

        let revealedChar = answerChars[index]
        revealedPositions.insert(index)

        let tile = tileGrid[row][index]
        tile.update(letter: revealedChar, state: .correct)
        updateCurrentGuess()
    }

    // MARK: - Keyboard
    private func setupKeyboard() {
        keyboardStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keyboardStack.axis = .vertical
        keyboardStack.spacing = 8
        keyboardStack.distribution = .fillEqually

        let rows: [[String]] = [
            ["Q","W","E","R","T","Y","U","I","O","P"],
            ["A","S","D","F","G","H","J","K","L"],
            ["✓","Z","X","C","V","B","N","M","⌫"]
        ]

        for rowKeys in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 6
            rowStack.distribution = .fillEqually

            for key in rowKeys {
                let button = makeKey(title: key)
                rowStack.addArrangedSubview(button)
            }
            keyboardStack.addArrangedSubview(rowStack)
        }
    }

    private func makeKey(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemGray5
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 6
        
        if title == "⌫" {
            button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        } else if title == "✓" {
            button.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
            button.backgroundColor = .systemBlue.withAlphaComponent(0.2)
        } else {
            button.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
        }
        return button
    }

    @objc func letterTapped(_ sender: UIButton) {
        guard let letter = sender.titleLabel?.text else { return }
        addLetter(Character(letter.lowercased()))
    }
    @objc func deleteTapped() { removeLetter() }
    @objc func submitTapped() { submitGuess() }

    // MARK: - Helpers
    private func render(_ result: GuessResult, row: Int) {
        let row = engine.attempts - 1
        for (i, evaluation) in result.evaluations.enumerated() {
            let tile = tileGrid[row][i]
            UIView.transition(with: tile, duration: 0.3, options: .transitionFlipFromTop) {
                tile.update(letter: evaluation.character, state: evaluation.state)
            }
        }
    }
    
    private func updateKeyboard(with result: GuessResult) {
        for evaluation in result.evaluations {
            let letter = evaluation.character
            let newState = evaluation.state
            if let old = keyStates[letter], old == .correct { continue }
            keyStates[letter] = newState
            
            let letterString = String(letter).uppercased()
            for row in keyboardStack.arrangedSubviews {
                guard let rowStack = row as? UIStackView else { continue }
                for view in rowStack.arrangedSubviews {
                    guard let button = view as? UIButton, button.title(for: .normal) == letterString else { continue }
                    let color: UIColor
                    switch newState {
                    case .correct: color = .systemGreen
                    case .present: color = .systemYellow
                    case .absent: color = .systemGray3
                    default: color = .systemGray5
                    }
                    UIView.animate(withDuration: 0.25) {
                        button.backgroundColor = color
                        if newState != .empty { button.setTitleColor(.white, for: .normal) }
                    }
                }
            }
        }
    }

    private func shakeGrid() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, -2.0, 2.0, 0.0 ]
        gridContainer.layer.add(animation, forKey: "shake")
    }
    
    private func updateProgress(from result: GuessResult) {
        let greenCount = result.evaluations.filter { $0.state == .correct }.count
        let yellowCount = result.evaluations.filter { $0.state == .present }.count
        let increment = (Float(greenCount) * 0.10) + (Float(yellowCount) * 0.05)
        incrementProgress(by: increment)
    }
    
    private func incrementProgress(by value: Float) {
        progressScore = min(1.0, progressScore + value)
        ProfitPoints.setProgress(progressScore, animated: true)
    }
    
    private func slideHintText(_ text: String) {
        hintLabel.textColor = .label // Make text dark/light (readable) when showing actual hint
        UIView.animate(withDuration: 0.2, animations: {
            self.hintLabel.alpha = 0
            self.hintLabel.transform = CGAffineTransform(translationX: 0, y: -10)
        }) { _ in
            self.hintLabel.text = text
            self.hintLabel.transform = CGAffineTransform(translationX: 0, y: 10)
            UIView.animate(withDuration: 0.3) {
                self.hintLabel.alpha = 1
                self.hintLabel.transform = .identity
            }
        }
    }
    
    private func endGame(won: Bool) {
        isGameOver = true
        if won {
            // Simple Confetti Animation
            let emitter = CAEmitterLayer()
            emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: 0)
            emitter.emitterShape = .line
            emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)
            let cell = CAEmitterCell()
            cell.birthRate = 5
            cell.lifetime = 5.0
            cell.velocity = 100
            cell.scale = 0.1
            cell.contents = UIImage(systemName: "circle.fill")?.cgImage
            cell.color = UIColor.systemYellow.cgColor
            emitter.emitterCells = [cell]
            view.layer.addSublayer(emitter)
        }
        
        let sheet = LearnMoreViewController(
            word: engine.revealedAnswer.uppercased(),
            definition: "A Stack is a linear data structure which follows a particular order in which the operations are performed. The order may be LIFO (Last In First Out) or FILO (First In Last Out)."
        )
        sheet.modalPresentationStyle = .overFullScreen
        sheet.modalTransitionStyle = .crossDissolve
        present(sheet, animated: true)
    }
}
