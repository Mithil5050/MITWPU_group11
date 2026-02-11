import UIKit

// MARK: - 1. Definitions
struct StudyContent {
    var filename: String
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

    @IBOutlet weak var quizConfigurationView: UIView!
    @IBOutlet weak var flashcardConfigurationView: UIView!
    @IBOutlet weak var defaultConfigurationPlaceholder: UIView!
    
    @IBOutlet weak var flashcardCountStepper: UIStepper!
    @IBOutlet weak var flashcardCountLabel: UILabel!
    
    @IBOutlet weak var quizCountStepper: UIStepper!
    @IBOutlet weak var quizCountLabel: UILabel!
    
    @IBOutlet weak var quizTimerStepper: UIStepper!
    @IBOutlet weak var quizTimerLabel: UILabel!
    
    @IBOutlet weak var easyButton: UIButton!
    @IBOutlet weak var mediumButton: UIButton!
    @IBOutlet weak var hardButton: UIButton!
    
    // Loading Indicator
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCards()
        setupSteppers()
        setupDifficultyButtons()
        setupFonts()
        
        handleCardSelection(selectedCard: quizCardView, type: .quiz)
        updateDifficultyUI()
        setupLoadingIndicator()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupDividers()
    }
    
    private func setupFonts() {
        let labels = [flashcardCountLabel, quizCountLabel, quizTimerLabel]
        labels.forEach { label in
            label?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        }
        startCreationButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
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
    
    private func setupSteppers() {
        if let fcStepper = flashcardCountStepper {
            fcStepper.minimumValue = 5
            fcStepper.maximumValue = 30
            fcStepper.stepValue = 5
            fcStepper.value = Double(selectedCount)
            fcStepper.autorepeat = true
            flashcardCountLabel.text = "\(Int(fcStepper.value))"
        }
        
        if let qcStepper = quizCountStepper {
            qcStepper.minimumValue = 5
            qcStepper.maximumValue = 30
            qcStepper.stepValue = 5
            qcStepper.value = Double(selectedCount)
            qcStepper.autorepeat = true
            quizCountLabel.text = "\(Int(qcStepper.value))"
        }
        
        if let qtStepper = quizTimerStepper {
            qtStepper.minimumValue = 5
            qtStepper.maximumValue = 60
            qtStepper.stepValue = 5
            qtStepper.value = Double(selectedTime)
            qtStepper.autorepeat = true
            quizTimerLabel.text = "\(Int(qtStepper.value))"
        }
    }
    
    private func setupDifficultyButtons() {
        let buttons = [easyButton, mediumButton, hardButton]
        buttons.forEach {
            $0?.layer.cornerRadius = 12
            $0?.clipsToBounds = true
            $0?.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        }
    }
    
    private func setupDividers() {
        guard let quizView = quizConfigurationView,
              let countStepper = quizCountStepper else { return }
        
        quizView.subviews.filter { $0.tag == 888 }.forEach { $0.removeFromSuperview() }
        
        let divider = UIView()
        divider.backgroundColor = .systemGray5
        divider.tag = 888
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        quizView.addSubview(divider)
        
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.leadingAnchor.constraint(equalTo: quizView.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: quizView.trailingAnchor, constant: -16),
            divider.topAnchor.constraint(equalTo: countStepper.bottomAnchor, constant: 24)
        ])
    }

    private func updateDifficultyUI() {
        let allButtons = [easyButton, mediumButton, hardButton]
        for button in allButtons {
            button?.backgroundColor = UIColor.secondarySystemFill
            button?.setTitleColor(UIColor.systemGray, for: .normal)
        }
        
        switch currentDifficulty {
        case .easy:
            easyButton.backgroundColor = UIColor.systemGreen
            easyButton.setTitleColor(.white, for: .normal)
        case .medium:
            mediumButton.backgroundColor = UIColor.systemYellow
            mediumButton.setTitleColor(.black, for: .normal)
        case .hard:
            hardButton.backgroundColor = UIColor.systemRed
            hardButton.setTitleColor(.white, for: .normal)
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
        
        let title = (type == .none) ? "Start Creation" : "Generate \(type.description)"
        startCreationButton.setTitle(title, for: .normal)
    }

    @IBAction func stepperValueChanged(_ sender: UIStepper) {
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
    
    @IBAction func difficultyButtonTapped(_ sender: UIButton) {
        if sender == easyButton {
            currentDifficulty = .easy
        } else if sender == mediumButton {
            currentDifficulty = .medium
        } else if sender == hardButton {
            currentDifficulty = .hard
        }
        
        UIView.animate(withDuration: 0.2) {
            self.updateDifficultyUI()
        }
    }
    
    // MARK: - AI Creation Action (✅ Updated with Retry Logic)
    @IBAction func startCreationButtonTapped(_ sender: UIButton) {
        // 1. Get Topic Name & Source
        guard let sourceItem = inputSourceData?.first else {
            showError("No source material found.")
            return
        }
        
        let topicName = extractName(from: sourceItem)

        // 2. Get Difficulty
        let difficultyString: String
        switch currentDifficulty {
        case .easy: difficultyString = "Easy"
        case .medium: difficultyString = "Medium"
        case .hard: difficultyString = "Hard"
        }
        
        // 3. UI: Start Loading
        sender.isEnabled = false
        sender.setTitle("Reading File...", for: .normal)
        loadingIndicator.startAnimating()
        view.isUserInteractionEnabled = false

        // 4. Call AI Asynchronously
        Task {
            // A. Extract Content (Text from PDF/Image/String)
            let extractedText = await ContentExtractor.shared.extractContent(from: sourceItem)
            
            // Prepare Prompt
            let finalPrompt: String
            if !extractedText.isEmpty && extractedText.count > 20 {
                let safeText = String(extractedText.prefix(15000))
                finalPrompt = "CONTEXT:\n\(safeText)\n\nTOPIC REQUEST: \(topicName)"
            } else {
                finalPrompt = topicName
            }

            DispatchQueue.main.async {
                sender.setTitle("Generating AI Content...", for: .normal)
            }

            do {
                // B. Call AI with RETRY Logic
                let generatedContent = try await generateContentWithRetry(
                    topic: finalPrompt,
                    type: selectedMaterialType.description,
                    count: selectedCount,
                    difficulty: difficultyString
                )
                
                // C. Success
                DispatchQueue.main.async {
                    self.handleSuccess(
                        generatedContent: generatedContent,
                        topicName: topicName,
                        sender: sender
                    )
                }
                
            } catch {
                // D. Error
                DispatchQueue.main.async {
                    self.resetUI(sender)
                    self.showError("AI Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // ✅ RETRY HELPER (The Fix for Code 500)
    private func generateContentWithRetry(topic: String, type: String, count: Int, difficulty: String, attempt: Int = 1) async throws -> String {
        do {
            return try await AIContentManager.shared.generateContent(
                topic: topic,
                type: type,
                count: count,
                difficulty: difficulty
            )
        } catch {
            print("⚠️ AI Attempt \(attempt) Failed: \(error.localizedDescription)")
            
            if attempt < 3 {
                print("⏳ Waiting 5 seconds before retrying...")
                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                return try await generateContentWithRetry(topic: topic, type: type, count: count, difficulty: difficulty, attempt: attempt + 1)
            } else {
                throw error
            }
        }
    }
    
    // ✅ Success Handler
    private func handleSuccess(generatedContent: String, topicName: String, sender: UIButton) {
        self.resetUI(sender)
        
        var newTopic: Topic?
        let subjectName = self.contextSubjectTitle ?? "General Study"
        
        if self.selectedMaterialType == .quiz {
            let parsedQuestions = self.parseQuizJSON(generatedContent)
            
            if parsedQuestions.isEmpty {
                self.showError("AI generated an empty or invalid quiz. Please try again.")
                return
            }
            
            newTopic = DataManager.shared.saveGeneratedTopic(
                name: topicName,
                subject: subjectName,
                type: "Quiz",
                questions: parsedQuestions
            )
            
        } else {
            newTopic = DataManager.shared.saveGeneratedTopic(
                name: topicName,
                subject: subjectName,
                type: self.selectedMaterialType.description,
                notes: generatedContent
            )
        }
        
        if let savedTopic = newTopic {
            self.navigateToResult(type: self.selectedMaterialType, topic: savedTopic, sourceName: topicName)
        } else {
            self.showError("Failed to save content.")
        }
    }
    
    // MARK: - UI Helpers (✅ ADDED MISSING FUNCTION)
    private func resetUI(_ sender: UIButton) {
        self.loadingIndicator.stopAnimating()
        self.view.isUserInteractionEnabled = true
        sender.isEnabled = true
        
        // Reset the button title based on selected type
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
            if let dest = segue.destination as? FlashcardsViewController,
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

// MARK: - JSON Parsing Helper
extension GenerateHomeViewController {
    
    func parseQuizJSON(_ jsonString: String) -> [QuizQuestion] {
        var cleanString = jsonString
        if cleanString.contains("```json") {
            cleanString = cleanString.replacingOccurrences(of: "```json", with: "")
            cleanString = cleanString.replacingOccurrences(of: "```", with: "")
        }
        cleanString = cleanString.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
                
                return QuizQuestion(
                    questionText: aiQ.question,
                    answers: aiQ.options,
                    correctAnswerIndex: correctIndex,
                    userAnswerIndex: nil,
                    isFlagged: false,
                    hint: aiQ.hint ?? "No hint available."
                )
            }
        } catch {
            print("⚠️ Failed to parse AI JSON: \(error)")
            if let directList = try? decoder.decode([QuizQuestion].self, from: data) {
                return directList
            }
        }
        
        return []
    }
}

// Helper Extension
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
