import UIKit

enum GenerationType {
    case quiz
    case flashcards
    case notes
    case cheatsheet
    case none
}

extension GenerationType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .quiz: return "Quiz"
        case .flashcards: return "Flashcards"
        case .notes: return "Notes"
        case .cheatsheet: return "Cheatsheet"
        case .none: return "Material"
        }
    }
}

struct ParsedAIFlashcard: Codable {
    let front: String?
    let back: String?
    let term: String?
    let definition: String?
    let keyword: String?
    
    var safeFront: String { return front ?? term ?? "Term" }
    var safeBack: String { return back ?? definition ?? "Definition" }
    var safeKeyword: String { return keyword ?? safeFront }
}

@IBDesignable
class MaterialSelectionCard: UIControl {
    private let stackView = UIStackView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) { super.init(frame: frame); setupView() }
    required init?(coder: NSCoder) { super.init(coder: coder); setupView() }
    
    private func setupView() {
        self.backgroundColor = .secondarySystemGroupedBackground
        self.layer.cornerRadius = 16
        
        iconImageView.contentMode = .scaleAspectFit
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 44),
            iconImageView.heightAnchor.constraint(equalToConstant: 44),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(iconName: String, title: String, iconColor: UIColor) {
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        titleLabel.text = title
        iconImageView.tintColor = iconColor
    }
    
    override var isSelected: Bool {
        didSet {
            self.layer.borderWidth = isSelected ? 2 : 0
            self.layer.borderColor = isSelected ? iconImageView.tintColor.cgColor : nil
            self.backgroundColor = isSelected ? iconImageView.tintColor.withAlphaComponent(0.05) : .secondarySystemGroupedBackground
        }
    }
}

class GenerationViewController: UIViewController {

    static var lastGenerationTime: Date?
    let requiredCooldown: TimeInterval = 8.0

    var currentGenerationType: GenerationType = .quiz
    var sourceItems: [Any]?
    var parentSubjectName: String?

    var selectedCount: Int = 10
    var selectedTime: Int = 15
    var currentDifficulty: DifficultyLevel = .easy
    
    enum DifficultyLevel {
        case easy, medium, hard
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    @IBOutlet weak var quizCard: MaterialSelectionCard!
    @IBOutlet weak var flashCard: MaterialSelectionCard!
    @IBOutlet weak var noteCard: MaterialSelectionCard!
    @IBOutlet weak var cheatCard: MaterialSelectionCard!
    
    @IBOutlet weak var QuizSettingsView: UIView!
    @IBOutlet weak var FlashcardSettingsView: UIView!
    @IBOutlet weak var emptySettingsPlaceholder: UIView!
    @IBOutlet weak var generateButton: UIButton!

    private let fcCountStepper = UIStepper()
    private let fcCountLabel = UILabel()
    
    private let qCountStepper = UIStepper()
    private let qCountLabel = UILabel()
    private let qTimeStepper = UIStepper()
    private let qTimeLabel = UILabel()
    
    private var allDifficultyButtons: [UIButton] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupProgrammaticUI()
        setupLoadingIndicator()

        updateUISelection(selected: quizCard, type: .quiz)
    }
    
    private func setupUI() {
            
            quizCard.configure(iconName: "timer", title: "Quiz", iconColor: UIColor(hex: "88D769"))
            flashCard.configure(iconName: "rectangle.on.rectangle.angled", title: "Flashcards", iconColor: UIColor(hex: "5AC8FA"))
            
            noteCard.configure(iconName: "book.pages", title: "Notes", iconColor: .systemOrange)
            cheatCard.configure(iconName: "list.clipboard", title: "Cheatsheet", iconColor: .systemPurple)
            
            let allCards = [quizCard, flashCard, noteCard, cheatCard]
            for card in allCards {
                card?.addTarget(self, action: #selector(handleCardTap(_:)), for: .touchUpInside)
            }
            
            generateButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
            generateButton.layer.cornerRadius = 12
        }
    
    private func setupProgrammaticUI() {
        guard let quizConfigView = QuizSettingsView,
              let flashcardConfigView = FlashcardSettingsView else { return }

        quizConfigView.subviews.forEach { $0.removeFromSuperview() }
        flashcardConfigView.subviews.forEach { $0.removeFromSuperview() }

        qCountStepper.minimumValue = 5; qCountStepper.maximumValue = 30; qCountStepper.stepValue = 5; qCountStepper.value = 10
        qCountLabel.text = "10"
        qCountStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        
        qTimeStepper.minimumValue = 5; qTimeStepper.maximumValue = 60; qTimeStepper.stepValue = 5; qTimeStepper.value = 15
        qTimeLabel.text = "15"
        qTimeStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        
        let qSettingsTitle = createTitleLabel("Settings")
        let qCountRow = createConfigRow(title: "Number of questions", stepper: qCountStepper, label: qCountLabel)
        let qTimeRow = createConfigRow(title: "Time Limit (minutes)", stepper: qTimeStepper, label: qTimeLabel)
        
        let quizStack = UIStackView(arrangedSubviews: [qSettingsTitle, qCountRow, qTimeRow])
        quizStack.axis = .vertical
        quizStack.spacing = 24
        quizStack.translatesAutoresizingMaskIntoConstraints = false
        
        quizConfigView.addSubview(quizStack)
        NSLayoutConstraint.activate([
            quizStack.leadingAnchor.constraint(equalTo: quizConfigView.leadingAnchor, constant: 4),
            quizStack.trailingAnchor.constraint(equalTo: quizConfigView.trailingAnchor, constant: -4),
            quizStack.topAnchor.constraint(equalTo: quizConfigView.topAnchor, constant: 8)
        ])

        fcCountStepper.minimumValue = 5; fcCountStepper.maximumValue = 30; fcCountStepper.stepValue = 5; fcCountStepper.value = 10
        fcCountLabel.text = "10"
        fcCountStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        
        let fcSettingsTitle = createTitleLabel("Settings")
        let fcCountRow = createConfigRow(title: "Number of flashcards", stepper: fcCountStepper, label: fcCountLabel)
        let diffTitle = createTitleLabel("Level of Difficulty", font: .systemFont(ofSize: 16, weight: .regular))
        let (fcDiffStack, fcBtns) = createDifficultyRow()
        allDifficultyButtons.append(contentsOf: fcBtns)
        
        let fcMainStack = UIStackView(arrangedSubviews: [fcSettingsTitle, fcCountRow, diffTitle, fcDiffStack])
        fcMainStack.axis = .vertical
        fcMainStack.spacing = 16
        fcMainStack.setCustomSpacing(24, after: fcCountRow)
        fcMainStack.translatesAutoresizingMaskIntoConstraints = false
        
        flashcardConfigView.addSubview(fcMainStack)
        NSLayoutConstraint.activate([
            fcMainStack.leadingAnchor.constraint(equalTo: flashcardConfigView.leadingAnchor, constant: 4),
            fcMainStack.trailingAnchor.constraint(equalTo: flashcardConfigView.trailingAnchor, constant: -4),
            fcMainStack.topAnchor.constraint(equalTo: flashcardConfigView.topAnchor, constant: 8)
        ])
        
        updateDifficultyUI()
    }
    
    private func createTitleLabel(_ text: String, font: UIFont = .systemFont(ofSize: 17, weight: .bold)) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = font
        lbl.textColor = .label
        return lbl
    }
    
    private func createConfigRow(title: String, stepper: UIStepper, label: UILabel) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.widthAnchor.constraint(equalToConstant: 30).isActive = true
        
        let rightStack = UIStackView(arrangedSubviews: [label, stepper])
        rightStack.spacing = 12
        rightStack.alignment = .center
        
        let mainStack = UIStackView(arrangedSubviews: [titleLabel, rightStack])
        mainStack.axis = .horizontal
        mainStack.distribution = .equalSpacing
        mainStack.alignment = .center
        return mainStack
    }
    
    private func createDifficultyRow() -> (UIStackView, [UIButton]) {
        let easyBtn = UIButton(type: .system)
        easyBtn.setTitle("Easy", for: .normal)
        let medBtn = UIButton(type: .system)
        medBtn.setTitle("Medium", for: .normal)
        let hardBtn = UIButton(type: .system)
        hardBtn.setTitle("Hard", for: .normal)
        
        let buttons = [easyBtn, medBtn, hardBtn]
        for btn in buttons {
            btn.layer.cornerRadius = 8
            btn.clipsToBounds = true
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            btn.addTarget(self, action: #selector(difficultyButtonTapped(_:)), for: .touchUpInside)
            btn.heightAnchor.constraint(equalToConstant: 34).isActive = true
        }
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        return (stack, buttons)
    }

    private func updateDifficultyUI() {
        for button in allDifficultyButtons {
            button.backgroundColor = UIColor.secondarySystemFill
            button.setTitleColor(UIColor.systemGray, for: .normal)
            
            let title = button.title(for: .normal)
            if title == "Easy" && currentDifficulty == .easy {
                button.backgroundColor = UIColor.systemGreen
                button.setTitleColor(.white, for: .normal)
            } else if title == "Medium" && currentDifficulty == .medium {
                button.backgroundColor = UIColor.systemYellow
                button.setTitleColor(.black, for: .normal)
            } else if title == "Hard" && currentDifficulty == .hard {
                button.backgroundColor = UIColor.systemRed
                button.setTitleColor(.white, for: .normal)
            }
        }
    }
    
    @objc func handleCardTap(_ sender: MaterialSelectionCard) {
        if sender == quizCard { updateUISelection(selected: quizCard, type: .quiz) }
        else if sender == flashCard { updateUISelection(selected: flashCard, type: .flashcards) }
        else if sender == noteCard { updateUISelection(selected: noteCard, type: .notes) }
        else if sender == cheatCard { updateUISelection(selected: cheatCard, type: .cheatsheet) }
    }
    
    private func updateUISelection(selected: MaterialSelectionCard, type: GenerationType) {
        self.currentGenerationType = type
        
        let allCards = [quizCard, flashCard, noteCard, cheatCard]
        for card in allCards {
            card?.isSelected = (card === selected)
        }
        
        QuizSettingsView.isHidden = (type != .quiz)
        FlashcardSettingsView.isHidden = (type != .flashcards)
        emptySettingsPlaceholder.isHidden = (type == .quiz || type == .flashcards)
        
        if type == .quiz { selectedCount = Int(qCountStepper.value) }
        else if type == .flashcards { selectedCount = Int(fcCountStepper.value) }
        
        generateButton.setTitle("Generate \(type.description)", for: .normal)
    }
    
    @objc func stepperValueChanged(_ sender: UIStepper) {
        let val = Int(sender.value)
        if sender == fcCountStepper {
            fcCountLabel.text = "\(val)"
            selectedCount = val
        } else if sender == qCountStepper {
            qCountLabel.text = "\(val)"
            selectedCount = val
        } else if sender == qTimeStepper {
            qTimeLabel.text = "\(val)"
            selectedTime = val
        }
    }
    
    @objc func difficultyButtonTapped(_ sender: UIButton) {
        let title = sender.title(for: .normal)
        if title == "Easy" { currentDifficulty = .easy }
        else if title == "Medium" { currentDifficulty = .medium }
        else if title == "Hard" { currentDifficulty = .hard }
        
        UIView.animate(withDuration: 0.2) {
            self.updateDifficultyUI()
        }
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .systemBlue
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @IBAction func generateButtonTapped(_ sender: UIButton) {
       
        if let lastTime = Self.lastGenerationTime {
            let timeSinceLast = Date().timeIntervalSince(lastTime)
            if timeSinceLast < requiredCooldown {
                let waitTime = Int(requiredCooldown - timeSinceLast)
                showError("Please wait \(waitTime) seconds before generating again to prevent rate limits.")
                return
            }
        }
        
        Self.lastGenerationTime = Date()
        
        guard let sourceItem = sourceItems?.first else {
            showError("No source material found.")
            return
        }
        
        var topicName = "General"
        if let topic = sourceItem as? Topic { topicName = topic.name }
        else if let source = sourceItem as? Source { topicName = source.name }
        else if let str = sourceItem as? String { topicName = str }
        else if let url = sourceItem as? URL { topicName = url.lastPathComponent }
        else if let studyContent = sourceItem as? StudyContent { topicName = studyContent.filename }

        let diffString: String
        switch currentDifficulty {
        case .easy: diffString = "Easy"
        case .medium: diffString = "Medium"
        case .hard: diffString = "Hard"
        }

        sender.isEnabled = false
        sender.setTitle("Generating...", for: .normal)
        view.isUserInteractionEnabled = false
        
        let materialName = currentGenerationType.description
        let overlayMessage: String
        switch currentGenerationType {
        case .quiz:       overlayMessage = "Crafting your quiz questions...\nThis may take a moment "
        case .flashcards: overlayMessage = "Building your flashcards...\nSit tight!"
        case .notes:      overlayMessage = "Writing your study notes...\nAlmost there!"
        case .cheatsheet: overlayMessage = "Preparing your cheatsheet...\nHang on!"
        case .none:       overlayMessage = "Our AI is generating your \(materialName)..."
        }
        showGenerationOverlay(message: overlayMessage)
        
        Task {
            let extractedText = await ContentExtractor.shared.extractContent(from: sourceItem)

            var instruction = ""
            switch currentGenerationType {
            case .flashcards:
                instruction = """
                Generate exactly \(selectedCount) flashcards covering the most important concepts.
                The difficulty should be \(diffString).
                
                STRICTLY FOLLOW THESE RULES:
                1. FRONT (term): Must be a CONCISE TERM or CONCEPT only (e.g., 'Mitochondria', 'Photosynthesis', 'Civil War').
                2. NO QUESTIONS on the front: NEVER use 'What is...?', 'Define...', 'Explain...', or any question/instruction form. ONLY nouns, terms, or concepts.
                3. BACK (definition): Provide a clear, educational definition or explanation of the front term.
                4. KEYWORD: Extract a single essential word from the 'front' term (lowercase, no parentheses).
                
                CORRECT example: front="Polysaccharide", back="A carbohydrate whose molecules consist of a number of sugar molecules bonded together."
                INCORRECT example: front="Define polysaccharide." ← this is FORBIDDEN.
                INCORRECT example: front="What is photosynthesis?" ← this is FORBIDDEN.
                
                STRICTLY use this EXACT JSON format:
                {
                  "flashcards": [
                    {
                      "front": "Concise Term (1-3 words)",
                      "back": "Detailed Definition",
                      "keyword": "lowercase_keyword"
                    }
                  ]
                }
                """
            case .cheatsheet:
                instruction = """
                You are an expert tutor creating a beautifully formatted Cheatsheet.
                DO NOT output JSON. Output ONLY plain text.
                You MUST use double line breaks (hit enter twice) to separate sections.
                You MUST use bullet points for lists.
                
                Structure the output EXACTLY like this visual template:
                
                ### CHEATSHEET: \(topicName)
                
                ### KEY CONCEPTS:
                 Concept 1: Definition goes here.
                 Concept 2: Definition goes here.
                
                ### FORMULAS & FACTS:
                 Fact or Formula 1
                 Fact or Formula 2
                
                ### QUICK SUMMARY:
                A short, readable summary goes here.
                """
            case .notes:
                instruction = """
                You are an expert tutor creating detailed Study Notes.
                DO NOT output JSON. Output ONLY plain text.
                You MUST use double line breaks (hit enter twice) to separate paragraphs and sections.
                You MUST use bullet points for lists.
                
                Structure the output EXACTLY like this visual template:
                
                ### STUDY NOTES: \(topicName)
                
                ### INTRODUCTION:
                Brief introduction goes here.
                
                ### MAIN TOPICS:
                 Topic 1: Detailed explanation here.
                 Topic 2: Detailed explanation here.
                
                ### EXAMPLES:
                 Example 1
                 Example 2
                """
            case .quiz:
                instruction = """
                Generate exactly \(selectedCount) quiz questions in JSON format.
                The test is designed to be solved within a \(selectedTime) minute limit.
                STRICTLY use this EXACT JSON format:
                {
                  "questions": [
                    {
                      "question": "Question text here?",
                      "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
                      "answer": "Option 1",
                      "hint": "Explanation here"
                    }
                  ]
                }
                """
            default: break
            }
            
            let safeText = String(extractedText.prefix(15000))
            let finalPrompt = "\(instruction)\n\nCONTEXT:\n\(safeText)\n\nTOPIC REQUEST: \(topicName)"
            
            await MainActor.run {
            }

            do {
                let generatedText = try await generateContentWithSmartWait(
                    topic: finalPrompt,
                    type: currentGenerationType.description,
                    count: selectedCount,
                    difficulty: diffString
                )
                
                DispatchQueue.main.async {
                    self.hideGenerationOverlay()
                    self.handleSuccess(generatedContent: generatedText, topicName: topicName, sender: sender)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.hideGenerationOverlay()
                    self.stopLoading(sender)
                    self.showError("AI Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func generateContentWithSmartWait(topic: String, type: String, count: Int, difficulty: String, attempt: Int = 1) async throws -> String {
        do {
            return try await AIContentManager.shared.generateContent(
                topic: topic,
                type: type,
                count: count,
                difficulty: difficulty
            )
        } catch {
            let errorString = error.localizedDescription.lowercased()
            let isQuotaError = errorString.contains("quota") || errorString.contains("429") || errorString.contains("exceeded")
            
            if attempt < 3 {
                if isQuotaError {
                    print(" QUOTA HIT. Waiting 70s...")
                    for i in (1...70).reversed() {
                        await MainActor.run { self.generateButton.setTitle("Limit Hit. Retrying in \(i)s...", for: .normal) }
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                } else {
                    try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                }
                return try await generateContentWithSmartWait(topic: topic, type: type, count: count, difficulty: difficulty, attempt: attempt + 1)
            } else {
                throw error
            }
        }
    }

    private func handleSuccess(generatedContent: String, topicName: String, sender: UIButton) {
        self.stopLoading(sender)
        
        let folder = self.parentSubjectName ?? "General Study"
        var savedTopic: Topic?
        
        // Clean the source name (strip file extensions, prefixes, underscores)
        let cleanSource = topicName
            .replacingOccurrences(of: ".txt", with: "")
            .replacingOccurrences(of: ".pdf", with: "")
            .replacingOccurrences(of: ".docx", with: "")
            .replacingOccurrences(of: "Note_", with: "")
            .replacingOccurrences(of: "Link_", with: "")
            .replacingOccurrences(of: "Source_", with: "")
            .replacingOccurrences(of: "Doc_", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespaces)
            .capitalized
        
        // Material name = "SourceName MaterialType" e.g. "English Flashcards"
        let materialName = "\(cleanSource) \(currentGenerationType.description)"
        
        if let items = self.sourceItems {
            for item in items {
                if let url = item as? URL {
                    DataManager.shared.importFile(url: url, subject: folder)
                } else if let str = item as? String {
                    if str.hasPrefix("/") || str.hasPrefix("file://") {
                        let url = URL(fileURLWithPath: str)
                        DataManager.shared.importFile(url: url, subject: folder)
                    } else if str.lowercased().hasPrefix("http://") || str.lowercased().hasPrefix("https://") {
                        let linkSource = Source(name: str, fileType: "LINK", size: "Web Link")
                        DataManager.shared.saveContent(subject: folder, content: linkSource)
                    }
                }
            }
        }

        if self.currentGenerationType == .quiz {
            let questions = self.parseQuizJSON(generatedContent)
            if questions.isEmpty { self.showError("AI generated invalid quiz data."); return }
            savedTopic = DataManager.shared.saveGeneratedTopic(name: materialName, subject: folder, type: "Quiz", questions: questions, sourceName: cleanSource)
            
        } else if self.currentGenerationType == .flashcards {
            let parsedCards = self.parseFlashcardsJSON(generatedContent)
            if parsedCards.isEmpty { self.showError("AI generated invalid flashcard data."); return }
            
            let serialized = parsedCards.map { "\($0.safeFront)|\($0.safeBack)|\($0.safeKeyword)" }.joined(separator: "\n")
            savedTopic = DataManager.shared.saveGeneratedTopic(name: materialName, subject: folder, type: "Flashcards", notes: serialized, sourceName: cleanSource)
            
        } else {
           
            var finalText = generatedContent.trimmingCharacters(in: .whitespacesAndNewlines)
            if finalText.hasPrefix("```markdown") {
                finalText = finalText.replacingOccurrences(of: "```markdown", with: "")
                finalText = finalText.replacingOccurrences(of: "```", with: "")
            }
            
            savedTopic = DataManager.shared.saveGeneratedTopic(name: materialName, subject: folder, type: self.currentGenerationType.description, notes: finalText, sourceName: cleanSource)
        }

        if let finalTopic = savedTopic {
            let payload = (topic: finalTopic, sourceName: cleanSource)
            self.performNavigation(type: self.currentGenerationType, payload: payload)
            
            Task { await RevisioManager.shared.earnXP(amount: 5, reason: "Material Generated") }
        }
    }

    func performNavigation(type: GenerationType, payload: (topic: Topic, sourceName: String)) {
        switch type {
        case .quiz: performSegue(withIdentifier: "ShowQuizInstructionsFromGen", sender: payload)
        case .notes, .cheatsheet: performSegue(withIdentifier: "ShowMaterial", sender: payload)
        case .flashcards: performSegue(withIdentifier: "HomeToFlashcardView", sender: payload)
        case .none: break
        }
    }
    
    func stopLoading(_ sender: UIButton) {
        view.isUserInteractionEnabled = true
        sender.isEnabled = true
        sender.setTitle("Generate \(currentGenerationType.description)", for: .normal)
    }
    
    func showError(_ msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let data = sender as? (topic: Topic, sourceName: String) else { return }
        
        if segue.identifier == "ShowQuizInstructionsFromGen" {
            if let dest = segue.destination as? InstructionViewController {
                dest.quizTopic = data.topic
                dest.sourceNameForQuiz = data.sourceName
                dest.quizTimeLimit = self.selectedTime
                dest.quizQuestionCount = self.selectedCount
                dest.parentSubjectName = self.parentSubjectName
            }
        } else if segue.identifier == "ShowMaterial" {
            if let dest = segue.destination as? MaterialGenerationViewController {
                dest.contentData = data.topic
                dest.parentSubjectName = self.parentSubjectName
                dest.materialType = self.currentGenerationType.description
            }
        } else if segue.identifier == "HomeToFlashcardView" {
            if let dest = segue.destination as? FlashcardsViewController {
                dest.currentTopic = data.topic
                dest.parentSubjectName = self.parentSubjectName
                dest.isFromGenerationScreen = true
            } else if let dest = segue.destination as? FlashcardViewController {
                dest.currentTopic = data.topic
                dest.parentSubjectName = self.parentSubjectName
            }
        }
    }
}

extension GenerationViewController {
    
    func parseQuizJSON(_ jsonString: String) -> [QuizQuestion] {
        let cleanString = cleanJSONText(jsonString)
        guard let data = cleanString.data(using: .utf8) else { return [] }
        
        struct AIResponse: Codable {
            struct AIQuestion: Codable {
                let question: String
                let options: [String]
                let answer: String
                let hint: String?
            }
            let questions: [AIQuestion]
        }
        
        let decoder = JSONDecoder()
        do {
            let wrapper = try decoder.decode(AIResponse.self, from: data)
            return wrapper.questions.map { aiQ in
                let correctIndex = aiQ.options.firstIndex(of: aiQ.answer) ?? 0
                return QuizQuestion(questionText: aiQ.question, answers: aiQ.options, correctAnswerIndex: correctIndex, userAnswerIndex: nil, isFlagged: false, hint: aiQ.hint ?? "No hint available.")
            }
        } catch {
            if let directList = try? decoder.decode([QuizQuestion].self, from: data) {
                return directList
            }
        }
        return []
    }
    
    func parseFlashcardsJSON(_ jsonString: String) -> [ParsedAIFlashcard] {
        let cleanString = cleanJSONText(jsonString)
        guard let data = cleanString.data(using: .utf8) else { return [] }
        
        let decoder = JSONDecoder()
        
        if let cards = try? decoder.decode([ParsedAIFlashcard].self, from: data) {
            return cards
        }
        
        struct AIWrapper: Codable { let flashcards: [ParsedAIFlashcard] }
        if let wrapper = try? decoder.decode(AIWrapper.self, from: data) {
            return wrapper.flashcards
        }
        
        print(" Failed to parse flashcards JSON. Raw Data: \(cleanString)")
        return []
    }
    
    private func cleanJSONText(_ json: String) -> String {
        var clean = json
        if clean.contains("```json") { clean = clean.replacingOccurrences(of: "```json", with: "") }
        clean = clean.replacingOccurrences(of: "```", with: "")
        
        if let startIndex = clean.firstIndex(of: "{") {
            clean = String(clean[startIndex...])
        } else if let startIndex = clean.firstIndex(of: "[") {
            clean = String(clean[startIndex...])
        }
        
        if let endIndex = clean.lastIndex(of: "}") {
            clean = String(clean[...endIndex])
        } else if let endIndex = clean.lastIndex(of: "]") {
            clean = String(clean[...endIndex])
        }
        
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
