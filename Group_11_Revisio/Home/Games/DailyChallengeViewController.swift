import UIKit

// MARK: - AI Model
struct AIWordleResponse: Codable {
    let word: String
    let hints: [String]
    let definition: String
}

class DailyChallengeViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var ProfitPoints: UIProgressView!
    @IBOutlet weak var keyboardStack: UIStackView!
    @IBOutlet weak var gridContainer: UIStackView!
    @IBOutlet weak var revealButton: UIButton!
    
    // MARK: - Properties
    private var tileGrid: [[LetterTileView]] = []
    private var keyStates: [Character: LetterTileView.State] = [:]
    private var isGameOver = false
    
    // Dynamic Data
    private var hints: [String] = []
    private var wordDefinition: String = ""
    private var engine: WordleEngine!
    
    private var revealedPositions: Set<Int> = []
    private var currentHintIndex = 0
    private var revealUsed = false
    private var progressScore: Float = 0.0
    private var currentGuess = ""

    // Loading UI
    private let loadingOverlay = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let loadingLabel = UILabel()
    
    // MARK: - Daily State Management
    private let defaults = UserDefaults.standard
    private let lastDateKey = "DailyWordle_LastDate"
    private let wordKey = "DailyWordle_Word"
    private let hintsKey = "DailyWordle_Hints"
    private let defKey = "DailyWordle_Definition"
    private let completedKey = "DailyWordle_Completed"
    
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        buildGrid()
        setupKeyboard()
        
        setupLoadingOverlay()
        handleDailyWordle()
    }
    
    private func setupUI() {
        title = "Daily Challenge"
        view.backgroundColor = .systemBackground
        
        hintLabel.alpha = 0
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
        hintLabel.text = "Tap the bulb above for a hint!"
        hintLabel.textColor = .secondaryLabel
        
        UIView.animate(withDuration: 0.5, delay: 0.5) {
            self.hintLabel.alpha = 1
        }
        
        ProfitPoints.layer.cornerRadius = 4
        ProfitPoints.clipsToBounds = true
    }
    
    private func setupLoadingOverlay() {
        loadingOverlay.backgroundColor = .systemBackground
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingOverlay)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .systemBlue
        loadingIndicator.startAnimating()
        loadingOverlay.addSubview(loadingIndicator)
        
        loadingLabel.text = "Loading today's puzzle..."
        loadingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        loadingLabel.textColor = .secondaryLabel
        loadingLabel.textAlignment = .center
        loadingLabel.numberOfLines = 0
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor, constant: -20),
            
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingOverlay.leadingAnchor, constant: 32),
            loadingLabel.trailingAnchor.constraint(equalTo: loadingOverlay.trailingAnchor, constant: -32)
        ])
    }

    // MARK: - ✅ DAILY GENERATION LOGIC
    private func handleDailyWordle() {
        let lastDate = defaults.string(forKey: lastDateKey)
        
        if lastDate == todayString {
            // Already generated today
            if defaults.bool(forKey: completedKey) {
                // User already finished today's puzzle
                showAlreadyPlayedAlert()
            } else {
                // User started but didn't finish. Load saved puzzle instantly.
                let savedWord = defaults.string(forKey: wordKey) ?? "STACK"
                let savedHints = defaults.stringArray(forKey: hintsKey) ?? []
                let savedDef = defaults.string(forKey: defKey) ?? "A linear data structure."
                startGame(with: savedWord, hints: savedHints, definition: savedDef)
            }
        } else {
            // It's a new day! Reset completion and generate a new word.
            defaults.set(false, forKey: completedKey)
            loadingLabel.text = "Generating your puzzle from Study Materials..."
            generateWordleFromStudyMaterials()
        }
    }
    
    private func showAlreadyPlayedAlert() {
        loadingOverlay.removeFromSuperview()
        let alert = UIAlertController(
            title: "Come back tomorrow!",
            message: "You have already completed the Daily Wordle for today. Great job staying consistent!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func generateWordleFromStudyMaterials() {
        Task {
            let allTopics = DataManager.shared.getAllRecentTopics()
            let contextParts = allTopics.compactMap { $0.largeContentBody ?? $0.notesContent ?? $0.cheatsheetContent }
            let combinedContext = contextParts.joined(separator: "\n")
            let safeContext = String(combinedContext.prefix(15000))
            
            let prompt = """
            You are an educational game master. Based on the provided study materials, select ONE universally recognizable term.
            
            CRITICAL RULES:
            1. The word MUST be EXACTLY 5 letters long.
            2. NO special characters, NO numbers, NO spaces.
            3. Generate 2 helpful hints for guessing this word.
            4. Generate a short, educational definition (1-2 sentences).
            5. Output ONLY valid JSON in this exact format:
            {
              "word": "APPLE",
              "hints": ["A common red or green fruit.", "Keeps the doctor away."],
              "definition": "A round fruit with red or green skin and a whitish interior."
            }

            STUDY MATERIALS:
            \(safeContext.isEmpty ? "General Computer Science and General Knowledge concepts." : safeContext)
            """
            
            do {
                let jsonResponse = try await AIContentManager.shared.generateContent(
                    topic: prompt,
                    type: "Wordle",
                    count: 1,
                    difficulty: "Medium"
                )
                
                let cleanJSON = cleanJSONText(jsonResponse)
                guard let data = cleanJSON.data(using: .utf8) else { throw URLError(.cannotDecodeContentData) }
                
                let decoder = JSONDecoder()
                let result = try decoder.decode(AIWordleResponse.self, from: data)
                
                let finalWord = result.word.count == 5 ? result.word.uppercased() : "STACK"
                
                // ✅ SAVE TODAY'S PUZZLE TO USERDEFAULTS
                self.defaults.set(self.todayString, forKey: self.lastDateKey)
                self.defaults.set(finalWord, forKey: self.wordKey)
                self.defaults.set(result.hints, forKey: self.hintsKey)
                self.defaults.set(result.definition, forKey: self.defKey)
                
                DispatchQueue.main.async {
                    self.startGame(with: finalWord, hints: result.hints, definition: result.definition)
                }
            } catch {
                print("⚠️ AI Wordle Failed: \(error.localizedDescription). Using fallback.")
                // Save fallback so it doesn't try to regenerate continuously on error
                let fbWord = "ARRAY"
                let fbHints = ["A collection of elements.", "Uses index numbers."]
                let fbDef = "A data structure that stores a fixed-size sequential collection of elements."
                
                self.defaults.set(self.todayString, forKey: self.lastDateKey)
                self.defaults.set(fbWord, forKey: self.wordKey)
                self.defaults.set(fbHints, forKey: self.hintsKey)
                self.defaults.set(fbDef, forKey: self.defKey)
                
                DispatchQueue.main.async {
                    self.startGame(with: fbWord, hints: fbHints, definition: fbDef)
                }
            }
        }
    }
    
    private func startGame(with word: String, hints: [String], definition: String) {
        self.engine = WordleEngine(answer: word)
        self.hints = hints.isEmpty ? ["No hints available for this word."] : hints
        self.wordDefinition = definition
        
        UIView.animate(withDuration: 0.3, animations: {
            self.loadingOverlay.alpha = 0
        }) { _ in
            self.loadingOverlay.removeFromSuperview()
        }
    }
    
    private func cleanJSONText(_ json: String) -> String {
        var clean = json
        if clean.contains("```json") { clean = clean.replacingOccurrences(of: "```json", with: "") }
        clean = clean.replacingOccurrences(of: "```", with: "")
        if let startIndex = clean.firstIndex(of: "{") { clean = String(clean[startIndex...]) }
        if let endIndex = clean.lastIndex(of: "}") { clean = String(clean[...endIndex]) }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Navigation Bar Setup
    private func setupNavigationBar() {
        let hintBtn = UIBarButtonItem(
            image: UIImage(systemName: "lightbulb.max"),
            style: .plain,
            target: self,
            action: #selector(hintTapped)
        )
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
        guard !isGameOver, engine != nil else { return }
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
        guard !isGameOver, engine != nil else { return }
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
        guard !isGameOver, engine != nil else { return }
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
        guard engine != nil else { return }
        guard currentHintIndex < hints.count else {
            let alert = UIAlertController(title: "No more hints!", message: "You're on your own now.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let newHint = hints[currentHintIndex]
        currentHintIndex += 1
        slideHintText(newHint)
        incrementProgress(by: -0.05) // Penalty
    }
    
    @IBAction func revealAlphabetTapped(_ sender: UIButton) {
        guard !isGameOver, !revealUsed, engine != nil else { return }
        
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
        hintLabel.textColor = .label
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
        ProgressDataManager.shared.totalDailyChallengesSolved += 1
        isGameOver = true
        
        // ✅ MARK GAME AS COMPLETED FOR TODAY
        defaults.set(true, forKey: completedKey)
        
        if won {
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
            
            Task { await RevisioManager.shared.earnXP(amount: 15, reason: "Won Daily Wordle") }
        }
        
        let sheet = LearnMoreViewController(
            word: engine.revealedAnswer.uppercased(),
            definition: wordDefinition
        )
        sheet.modalPresentationStyle = .overFullScreen
        sheet.modalTransitionStyle = .crossDissolve
        present(sheet, animated: true)
    }
}
