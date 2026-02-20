import UIKit

// MARK: - 1. Definitions
struct StudyContent {
    var filename: String
}

// ✅ FLASHCARD STRUCT
struct GeneratedFlashcard: Codable {
    let front: String?
    let back: String?
    let term: String?
    let definition: String?
    
    var safeFront: String {
        return front ?? term ?? "Term"
    }
    var safeBack: String {
        return back ?? definition ?? "Definition"
    }
}

// MARK: - Custom Card View
@IBDesignable
class TappableCardView: UIControl {
    
    private let stackView = UIStackView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private var highlightColor: UIColor = .systemBlue
    private var defaultBackgroundColor: UIColor = .secondarySystemGroupedBackground
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = defaultBackgroundColor
        self.layer.cornerRadius = 16
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.05
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 4
        
        iconImageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -8)
        ])
    }
    
    func configure(iconName: String, title: String, iconColor: UIColor) {
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        titleLabel.text = title
        iconImageView.tintColor = iconColor
        self.highlightColor = iconColor
    }
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = defaultBackgroundColor
            self.layer.borderWidth = isSelected ? 3 : 0
            self.layer.borderColor = isSelected ? highlightColor.cgColor : nil
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
                self.backgroundColor = self.defaultBackgroundColor
            }
        }
    }
    
    // ✅ TOUCH TRACKING
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        isHighlighted = true
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        isHighlighted = false
        if let touch = touch, bounds.contains(touch.location(in: self)) {
            sendActions(for: .touchUpInside)
        }
    }
    
    override func cancelTracking(with event: UIEvent?) {
        isHighlighted = false
    }
}

// MARK: - View Controller
class GenerateHomeViewController: UIViewController {

    var selectedMaterialType: GenerationType = .none
    var inputSourceData: [Any]?
    var contextSubjectTitle: String?
    
    var selectedCount: Int = 10
    var selectedTime: Int = 15
    var currentDifficulty: DifficultyLevel = .medium

    enum DifficultyLevel {
        case easy, medium, hard
    }

    @IBOutlet weak var startCreationButton: UIButton!
    
    @IBOutlet weak var quizCardView: TappableCardView!
    @IBOutlet weak var flashcardsCardView: TappableCardView!
    @IBOutlet weak var notesCardView: TappableCardView!
    @IBOutlet weak var cheatsheetCardView: TappableCardView!

    // Empty containers in Storyboard
    @IBOutlet weak var quizConfigurationView: UIView!
    @IBOutlet weak var flashcardConfigurationView: UIView!
    @IBOutlet weak var defaultConfigurationPlaceholder: UIView!
    
    // ✅ PROGRAMMATIC UI ELEMENTS
    private let flashcardCountStepper = UIStepper()
    private let flashcardCountLabel = UILabel()
    
    private let quizCountStepper = UIStepper()
    private let quizCountLabel = UILabel()
    private let quizTimerStepper = UIStepper()
    private let quizTimerLabel = UILabel()
    
    private let easyButton = UIButton(type: .system)
    private let mediumButton = UIButton(type: .system)
    private let hardButton = UIButton(type: .system)
    private var allDifficultyButtons: [UIButton] = []
    
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCards()
        setupProgrammaticUI() // ✅ Injects Steppers & Difficulty completely in code
        
        startCreationButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        // Default to Quiz
        handleCardSelection(selectedCard: quizCardView, type: .quiz)
        updateDifficultyUI()
        setupLoadingIndicator()
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .systemBlue
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupCards() {
        let quizColor = UIColor(hex: "88D769")
        let flashcardColor = UIColor(hex: "5AC8FA")
        let notesColor = UIColor(hex: "FF9F0A")
        let cheatsheetColor = UIColor(hex: "BF5AF2")
        
        quizCardView.configure(iconName: "timer", title: "Quiz", iconColor: quizColor)
        flashcardsCardView.configure(iconName: "rectangle.on.rectangle.angled", title: "Flashcards", iconColor: flashcardColor)
        notesCardView.configure(iconName: "book.pages", title: "Notes", iconColor: notesColor)
        cheatsheetCardView.configure(iconName: "list.clipboard", title: "Cheatsheet", iconColor: cheatsheetColor)
        
        // Button Actions
        quizCardView.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.handleCardSelection(selectedCard: self.quizCardView, type: .quiz)
        }, for: .touchUpInside)
        
        flashcardsCardView.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.handleCardSelection(selectedCard: self.flashcardsCardView, type: .flashcards)
        }, for: .touchUpInside)
        
        notesCardView.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.handleCardSelection(selectedCard: self.notesCardView, type: .notes)
        }, for: .touchUpInside)
        
        cheatsheetCardView.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.handleCardSelection(selectedCard: self.cheatsheetCardView, type: .cheatsheet)
        }, for: .touchUpInside)
        
        startCreationButton.layer.cornerRadius = 14
    }
    
    // MARK: - ✅ PROGRAMMATIC UI INJECTION
    private func setupProgrammaticUI() {
        guard let quizConfigView = quizConfigurationView,
              let flashcardConfigView = flashcardConfigurationView else { return }
        
        // Clear containers just in case
        quizConfigView.subviews.forEach { $0.removeFromSuperview() }
        flashcardConfigView.subviews.forEach { $0.removeFromSuperview() }
        
        // --- 1. QUIZ SETTINGS (No Difficulty) ---
        quizCountStepper.minimumValue = 5
        quizCountStepper.maximumValue = 30
        quizCountStepper.stepValue = 5
        quizCountStepper.value = Double(selectedCount)
        quizCountLabel.text = "\(selectedCount)"
        quizCountStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        
        quizTimerStepper.minimumValue = 5
        quizTimerStepper.maximumValue = 60
        quizTimerStepper.stepValue = 5
        quizTimerStepper.value = Double(selectedTime)
        quizTimerLabel.text = "\(selectedTime)"
        quizTimerStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        
        let qSettingsTitle = createTitleLabel("Settings")
        let qCountRow = createConfigRow(title: "Number of questions", stepper: quizCountStepper, label: quizCountLabel)
        let qTimeRow = createConfigRow(title: "Time Limit (minutes)", stepper: quizTimerStepper, label: quizTimerLabel)
        
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
        
        // --- 2. FLASHCARD SETTINGS (With Difficulty) ---
        flashcardCountStepper.minimumValue = 5
        flashcardCountStepper.maximumValue = 30
        flashcardCountStepper.stepValue = 5
        flashcardCountStepper.value = Double(selectedCount)
        flashcardCountLabel.text = "\(selectedCount)"
        flashcardCountStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        
        let fcSettingsTitle = createTitleLabel("Settings")
        let fcCountRow = createConfigRow(title: "Number of flashcards", stepper: flashcardCountStepper, label: flashcardCountLabel)
        let diffTitle = createTitleLabel("Level of Difficulty", font: .systemFont(ofSize: 16, weight: .regular))
        let fcDiffStack = createDifficultyRow()
        
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
    }
    
    // Helpers to create perfect programmatic views
    private func createTitleLabel(_ text: String, font: UIFont = .systemFont(ofSize: 17, weight: .semibold)) -> UILabel {
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
    
    private func createDifficultyRow() -> UIStackView {
        easyButton.setTitle("Easy", for: .normal)
        mediumButton.setTitle("Medium", for: .normal)
        hardButton.setTitle("Hard", for: .normal)
        
        allDifficultyButtons = [easyButton, mediumButton, hardButton]
        
        for btn in allDifficultyButtons {
            btn.layer.cornerRadius = 8
            btn.clipsToBounds = true
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            btn.addTarget(self, action: #selector(difficultyButtonTapped(_:)), for: .touchUpInside)
            btn.heightAnchor.constraint(equalToConstant: 34).isActive = true
        }
        
        let stack = UIStackView(arrangedSubviews: allDifficultyButtons)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        return stack
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

    private func handleCardSelection(selectedCard: TappableCardView, type: GenerationType) {
        self.selectedMaterialType = type
        
        let allCards = [quizCardView, flashcardsCardView, notesCardView, cheatsheetCardView]
        allCards.forEach { $0?.isSelected = ($0 === selectedCard) }
        
        quizConfigurationView.isHidden = (type != .quiz)
        flashcardConfigurationView.isHidden = (type != .flashcards)
        
        let isPlaceholderVisible = (type == .notes || type == .cheatsheet)
        defaultConfigurationPlaceholder.isHidden = !isPlaceholderVisible
        
        // Sync selected counts
        if type == .quiz {
            selectedCount = Int(quizCountStepper.value)
        } else if type == .flashcards {
            selectedCount = Int(flashcardCountStepper.value)
        }
        
        let title = (type == .none) ? "Start Creation" : "Generate \(type.description)"
        startCreationButton.setTitle(title, for: .normal)
    }

    @objc func stepperValueChanged(_ sender: UIStepper) {
        let intValue = Int(sender.value)
        
        if sender == flashcardCountStepper {
            flashcardCountLabel.text = "\(intValue)"
            selectedCount = intValue
        }
        else if sender == quizCountStepper {
            quizCountLabel.text = "\(intValue)"
            selectedCount = intValue
        }
        else if sender == quizTimerStepper {
            quizTimerLabel.text = "\(intValue)"
            selectedTime = intValue
        }
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
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
    
    // MARK: - AI Creation Action
    @IBAction func startCreationButtonTapped(_ sender: UIButton) {
        let topicName: String
        if let sourceItem = inputSourceData?.first {
            topicName = extractName(from: sourceItem)
        } else {
            topicName = "New Material"
        }

        let difficultyString: String
        switch currentDifficulty {
        case .easy: difficultyString = "Easy"
        case .medium: difficultyString = "Medium"
        case .hard: difficultyString = "Hard"
        }
        
        sender.isEnabled = false
        sender.setTitle("Processing...", for: .normal)
        loadingIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        Task {
            guard let sourceItem = inputSourceData?.first else {
                DispatchQueue.main.async {
                    self.showError("No source material found.")
                    self.resetUI(sender)
                }
                return
            }
            
            let extractedText = await ContentExtractor.shared.extractContent(from: sourceItem)
            
            var instruction = ""
            switch selectedMaterialType {
            case .flashcards:
                instruction = "Create exactly \(selectedCount) flashcards covering the most important concepts. Return ONLY a JSON array of objects with 'front' and 'back' keys. No Markdown. No extra text."
                
            case .cheatsheet:
                instruction = """
                STRICTLY GENERATE A CHEATSHEET.
                DO NOT generate a quiz. DO NOT output JSON.
                Format as clean MARKDOWN text.
                Include:
                - # Title
                - ## Key Formulas
                - ## Important Dates
                - ## Bulleted Definitions
                
                Topic: \(topicName)
                """
                
            case .notes:
                instruction = """
                STRICTLY GENERATE STUDY NOTES.
                DO NOT generate a quiz. DO NOT output JSON.
                Format as clean MARKDOWN text.
                Include:
                - # Main Heading
                - ## Subheadings
                - Bullet points for key concepts.
                - Examples where applicable.
                
                Topic: \(topicName)
                """
                
            case .quiz:
                instruction = "Generate exactly \(selectedCount) quiz questions in JSON format. The test is designed to be solved within a \(selectedTime) minute limit."
                
            default: break
            }
            
            let safeText = String(extractedText.prefix(15000))
            let finalPrompt = "\(instruction)\n\nCONTEXT:\n\(safeText)\n\nTOPIC REQUEST: \(topicName)"
            
            await MainActor.run {
                sender.setTitle("Generating AI Content...", for: .normal)
            }

            do {
                let generatedContent = try await generateContentWithSmartWait(
                    topic: finalPrompt,
                    type: selectedMaterialType.description,
                    count: selectedCount,
                    difficulty: difficultyString
                )
                
                DispatchQueue.main.async {
                    self.handleSuccess(
                        generatedContent: generatedContent,
                        topicName: topicName,
                        sender: sender
                    )
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.resetUI(sender)
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
            print("⚠️ AI Attempt \(attempt) Failed: \(error.localizedDescription)")
            
            let isQuotaError = errorString.contains("quota") ||
                               errorString.contains("limit") ||
                               errorString.contains("429") ||
                               errorString.contains("500") ||
                               errorString.contains("exceeded")
            
            if attempt < 3 {
                if isQuotaError {
                    print("🚨 QUOTA HIT. Waiting 70s...")
                    for i in (1...70).reversed() {
                        await MainActor.run {
                            self.startCreationButton.setTitle("Limit Hit. Retrying in \(i)s...", for: .normal)
                        }
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                } else {
                    print("🔄 Normal Retry (3s)...")
                    try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                }
                
                return try await generateContentWithSmartWait(topic: topic, type: type, count: count, difficulty: difficulty, attempt: attempt + 1)
            } else {
                throw error
            }
        }
    }
    
    private func handleSuccess(generatedContent: String, topicName: String, sender: UIButton) {
        self.resetUI(sender)
        
        let subjectName = self.contextSubjectTitle ?? "General Study"
        
        // ✅ NEW: Save the Original Source Files to the Folder
        if let items = self.inputSourceData {
            for item in items {
                if let url = item as? URL {
                    DataManager.shared.importFile(url: url, subject: subjectName)
                } else if let str = item as? String {
                    if str.hasPrefix("/") || str.hasPrefix("file://") {
                        let url = URL(fileURLWithPath: str)
                        DataManager.shared.importFile(url: url, subject: subjectName)
                    } else if str.lowercased().hasPrefix("http://") || str.lowercased().hasPrefix("https://") {
                        let linkSource = Source(name: str, fileType: "LINK", size: "Web Link")
                        DataManager.shared.saveContent(subject: subjectName, content: linkSource)
                    }
                }
            }
        }
        
        var newTopic: Topic?
        
        if self.selectedMaterialType == .quiz {
            let parsedQuestions = self.parseQuizJSON(generatedContent)
            if parsedQuestions.isEmpty {
                self.showError("AI generated an empty quiz. Please try again.")
                return
            }
            newTopic = DataManager.shared.saveGeneratedTopic(
                name: topicName,
                subject: subjectName,
                type: "Quiz",
                questions: parsedQuestions
            )
        } else if self.selectedMaterialType == .flashcards {
            
            // 1. Parse JSON into Array
            let parsedFlashcards = self.parseFlashcardsJSON(generatedContent)
            
            if parsedFlashcards.isEmpty {
                self.showError("AI generated empty flashcards. Please try again.")
                return
            }
            
            // 2. Format it into Term|Definition string
            let serializedCards = parsedFlashcards.map { "\($0.safeFront)|\($0.safeBack)" }.joined(separator: "\n")
            
            // 3. Save the formatted string to the database
            newTopic = DataManager.shared.saveGeneratedTopic(
                name: topicName,
                subject: subjectName,
                type: "Flashcards",
                notes: serializedCards
            )
        } else {
            let finalText: String
            if generatedContent.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") {
                finalText = convertJsonToMarkdown(json: generatedContent, type: self.selectedMaterialType.description)
            } else {
                finalText = generatedContent
            }
            
            newTopic = DataManager.shared.saveGeneratedTopic(
                name: topicName,
                subject: subjectName,
                type: self.selectedMaterialType.description,
                notes: finalText
            )
        }
        
        if let savedTopic = newTopic {
            self.navigateToResult(type: self.selectedMaterialType, topic: savedTopic, sourceName: topicName)
            
            Task {
                await RevisioManager.shared.earnXP(amount: 5, reason: "Material Generated")
            }
            
        } else {
            self.showError("Failed to save content.")
        }
    }
    
    // MARK: - UI Helpers
    private func resetUI(_ sender: UIButton) {
        self.loadingIndicator.stopAnimating()
        self.view.isUserInteractionEnabled = true
        sender.isEnabled = true
        let title = (selectedMaterialType == .none) ? "Start Creation" : "Generate \(selectedMaterialType.description)"
        sender.setTitle(title, for: .normal)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

    private func extractName(from item: Any) -> String {
        if let content = item as? StudyContent { return content.filename }
        if let topic = item as? Topic { return topic.name }
        if let str = item as? String { return str }
        if let url = item as? URL { return url.lastPathComponent }
        return "General Knowledge"
    }
    
    private func navigateToResult(type: GenerationType, topic: Topic, sourceName: String) {
        if type == .quiz {
            let payload = (topic: topic, sourceName: sourceName)
            performSegue(withIdentifier: "HomeToQuizInstruction", sender: payload)
        } else if type == .flashcards {
            performSegue(withIdentifier: "HomeToFlashcardView", sender: topic)
        } else if type == .notes {
            performSegue(withIdentifier: "HomeToNotesView", sender: topic)
        } else if type == .cheatsheet {
            performSegue(withIdentifier: "HomeToCheatsheetView", sender: topic)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HomeToQuizInstruction" {
            if let dest = segue.destination as? QuizStartViewController,
               let data = sender as? (topic: Topic, sourceName: String) {
                dest.currentTopic = data.topic
                dest.quizSourceName = data.sourceName
                dest.parentSubject = self.parentSubjectName()
            }
        }
        else if segue.identifier == "HomeToFlashcardView" {
            if let dest = segue.destination as? FlashcardViewController,
               let topic = sender as? Topic {
                dest.currentTopic = topic
                dest.parentSubjectName = self.parentSubjectName()
            }
        }
        else if segue.identifier == "HomeToNotesView" {
            if let dest = segue.destination as? NotesViewController,
               let topic = sender as? Topic {
                dest.currentTopic = topic
                dest.parentSubjectName = self.parentSubjectName()
            }
        }
        else if segue.identifier == "HomeToCheatsheetView" {
            if let dest = segue.destination as? CheatsheetViewController,
               let topic = sender as? Topic {
                dest.currentTopic = topic
                dest.parentSubjectName = self.parentSubjectName()
            }
        }
    }
    
    private func parentSubjectName() -> String {
        return self.contextSubjectTitle ?? "General Study"
    }
}

// MARK: - JSON Parsing Extensions
extension GenerateHomeViewController {
    
    func convertJsonToMarkdown(json: String, type: String) -> String {
        let stripped = json
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: ",", with: "\n")
        
        return "# Generated \(type) (Fallback)\n\n" + stripped
    }
    
    func parseQuizJSON(_ jsonString: String) -> [QuizQuestion] {
        let cleanString = cleanJSONString(jsonString)
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
        if let wrapper = try? decoder.decode(AIResponse.self, from: data) {
            return wrapper.questions.map { aiQ in
                let correctIndex = aiQ.options.firstIndex(of: aiQ.answer) ?? 0
                return QuizQuestion(questionText: aiQ.question, answers: aiQ.options, correctAnswerIndex: correctIndex, userAnswerIndex: nil, isFlagged: false, hint: aiQ.hint ?? "No hint")
            }
        } else if let directList = try? decoder.decode([QuizQuestion].self, from: data) {
            return directList
        }
        return []
    }
    
    // ✅ IMPROVED FLASHCARD PARSER
    func parseFlashcardsJSON(_ jsonString: String) -> [GeneratedFlashcard] {
        let cleanString = cleanJSONString(jsonString)
        guard let data = cleanString.data(using: .utf8) else { return [] }
        
        let decoder = JSONDecoder()
        
        // 1. Try treating it as a direct array: [{"front": "...", "back": "..."}]
        if let cards = try? decoder.decode([GeneratedFlashcard].self, from: data) {
            return cards
        }
        
        // 2. Try treating it as a wrapper object: {"flashcards": [{"front": "...", "back": "..."}]}
        struct AIWrapper: Codable {
            let flashcards: [GeneratedFlashcard]
        }
        if let wrapper = try? decoder.decode(AIWrapper.self, from: data) {
            return wrapper.flashcards
        }
        
        print("⚠️ Failed to parse flashcards JSON. Raw Data: \(cleanString)")
        return []
    }
    
    private func cleanJSONString(_ json: String) -> String {
        var clean = json
        if clean.contains("```json") {
            clean = clean.replacingOccurrences(of: "```json", with: "")
            clean = clean.replacingOccurrences(of: "```", with: "")
        }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
