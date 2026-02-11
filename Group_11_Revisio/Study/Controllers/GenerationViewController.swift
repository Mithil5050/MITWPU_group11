import UIKit

// MARK: - 1. Definitions
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

// MARK: - 2. Custom Control
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

// MARK: - 3. View Controller
class GenerationViewController: UIViewController {
    
    // PROPERTIES
    var currentGenerationType: GenerationType = .quiz
    var sourceItems: [Any]?
    var parentSubjectName: String?
    
    // SETTINGS
    var selectedCount: Int = 10
    var selectedTime: Int = 15
    var currentDifficulty: String = "Medium"
    
    // LOADING UI
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - IBOutlets
    @IBOutlet weak var quizCard: MaterialSelectionCard!
    @IBOutlet weak var flashCard: MaterialSelectionCard!
    @IBOutlet weak var noteCard: MaterialSelectionCard!
    @IBOutlet weak var cheatCard: MaterialSelectionCard!
    
    @IBOutlet weak var QuizSettingsView: UIView!
    @IBOutlet weak var FlashcardSettingsView: UIView!
    @IBOutlet weak var emptySettingsPlaceholder: UIView!
    @IBOutlet weak var generateButton: UIButton!
    
    // Steppers
    @IBOutlet weak var flashcardCountStepper: UIStepper!
    @IBOutlet weak var flashcardCountLabel: UILabel!
    
    @IBOutlet weak var quizCountStepper: UIStepper!
    @IBOutlet weak var quizCountLabel: UILabel!
    
    @IBOutlet weak var quizTimerStepper: UIStepper!
    @IBOutlet weak var quizTimerLabel: UILabel!
    
    // Difficulty
    @IBOutlet weak var easyButton: UIButton!
    @IBOutlet weak var mediumButton: UIButton!
    @IBOutlet weak var hardButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSteppers()
        setupLoadingIndicator()
        updateUISelection(selected: quizCard, type: .quiz)
        
        // Initial button styles
        let buttons = [easyButton, mediumButton, hardButton]
        for btn in buttons {
            btn?.layer.cornerRadius = 12
        }
        
        mediumButton.backgroundColor = .systemYellow
        mediumButton.setTitleColor(.black, for: .normal)
    }
    
    private func setupUI() {
        quizCard.configure(iconName: "timer", title: "Quiz", iconColor: UIColor(red: 0.45, green: 0.85, blue: 0.61, alpha: 1.0))
        flashCard.configure(iconName: "rectangle.on.rectangle.angled", title: "Flashcards", iconColor: .systemBlue)
        noteCard.configure(iconName: "book.pages", title: "Notes", iconColor: .systemOrange)
        cheatCard.configure(iconName: "list.clipboard", title: "Cheatsheet", iconColor: .systemPurple)
        
        let allCards = [quizCard, flashCard, noteCard, cheatCard]
        for card in allCards {
            card?.addTarget(self, action: #selector(handleCardTap(_:)), for: .touchUpInside)
        }
        
        generateButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        generateButton.layer.cornerRadius = 12
    }
    
    private func setupSteppers() {
        quizCountStepper.minimumValue = 5; quizCountStepper.maximumValue = 30; quizCountStepper.stepValue = 5; quizCountStepper.value = 10
        quizTimerStepper.minimumValue = 5; quizTimerStepper.maximumValue = 60; quizTimerStepper.stepValue = 5; quizTimerStepper.value = 15
        flashcardCountStepper.minimumValue = 5; flashcardCountStepper.maximumValue = 30; flashcardCountStepper.stepValue = 5; flashcardCountStepper.value = 10
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
        
        generateButton.setTitle("Generate \(type.description)", for: .normal)
    }

    // MARK: - CORE AI LOGIC
    @IBAction func generateButtonTapped(_ sender: UIButton) {
        // 1. Get the Topic Name
        guard let sourceItem = sourceItems?.first else { return }
        var topicName = "General"
        
        if let topic = sourceItem as? Topic {
            topicName = topic.name
        } else if let source = sourceItem as? Source {
            topicName = source.name
        } else if let str = sourceItem as? String {
            topicName = str
        }

        // 2. Start Loading UI
        sender.isEnabled = false
        sender.setTitle("Generating...", for: .normal)
        loadingIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        // 3. Trigger AI
        Task {
            do {
                let generatedText = try await AIContentManager.shared.generateContent(
                    topic: topicName,
                    type: currentGenerationType.description,
                    count: selectedCount,
                    difficulty: currentDifficulty
                )
                
                // 4. Save Data & Navigate
                DispatchQueue.main.async {
                    self.stopLoading(sender)
                    
                    var savedTopic: Topic?
                    
                    if self.currentGenerationType == .quiz {
                        // Parse JSON
                        let questions = self.parseQuizJSON(generatedText)
                        if questions.isEmpty {
                            self.showError("AI generated invalid quiz data.")
                            return
                        }
                        // Save Quiz
                        savedTopic = DataManager.shared.saveGeneratedTopic(
                            name: topicName,
                            subject: self.parentSubjectName ?? "General Study",
                            type: "Quiz",
                            questions: questions
                        )
                    } else {
                        // Save Notes/Flashcards/Cheatsheet
                        savedTopic = DataManager.shared.saveGeneratedTopic(
                            name: topicName,
                            subject: self.parentSubjectName ?? "General Study",
                            type: self.currentGenerationType.description,
                            notes: generatedText
                        )
                    }
                    
                    // Navigate
                    if let finalTopic = savedTopic {
                        let payload = (topic: finalTopic, sourceName: topicName)
                        self.performNavigation(type: self.currentGenerationType, payload: payload)
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.stopLoading(sender)
                    self.showError("AI Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Navigation Helper
    func performNavigation(type: GenerationType, payload: (topic: Topic, sourceName: String)) {
        switch type {
        case .quiz:
            performSegue(withIdentifier: "ShowQuizInstructionsFromGen", sender: payload)
        case .notes, .cheatsheet:
            performSegue(withIdentifier: "ShowMaterial", sender: payload)
        case .flashcards:
            performSegue(withIdentifier: "HomeToFlashcardView", sender: payload)
        case .none:
            break
        }
    }
    
    // UI Helpers
    func stopLoading(_ sender: UIButton) {
        loadingIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
        sender.isEnabled = true
        sender.setTitle("Generate \(currentGenerationType.description)", for: .normal)
    }
    
    func showError(_ msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Stepper Actions
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        let val = Int(sender.value)
        if sender == flashcardCountStepper {
            flashcardCountLabel.text = "\(val)"
            selectedCount = val
        } else if sender == quizCountStepper {
            quizCountLabel.text = "\(val)"
            selectedCount = val
        } else if sender == quizTimerStepper {
            quizTimerLabel.text = "\(val)"
            selectedTime = val
        }
    }
    
    // MARK: - Difficulty Actions
    @IBAction func difficultyTapped(_ sender: UIButton) {
        // ✅ FIXED: Replaced forEach with standard for loop to avoid "$0 is immutable" error
        let buttons = [easyButton, mediumButton, hardButton]
        for btn in buttons {
            btn?.backgroundColor = .systemGray6
            btn?.setTitleColor(.label, for: .normal)
        }
        
        sender.setTitleColor(.white, for: .normal)
        
        if sender == easyButton {
            sender.backgroundColor = .systemGreen
            currentDifficulty = "Easy"
        } else if sender == mediumButton {
            sender.backgroundColor = .systemYellow
            sender.setTitleColor(.black, for: .normal)
            currentDifficulty = "Medium"
        } else if sender == hardButton {
            sender.backgroundColor = .systemRed
            currentDifficulty = "Hard"
        }
    }
    
    // MARK: - Navigation Preparation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let data = sender as? (topic: Topic, sourceName: String) else { return }
        
        if segue.identifier == "ShowQuizInstructionsFromGen" {
            if let dest = segue.destination as? InstructionViewController {
                dest.quizTopic = data.topic
                dest.sourceNameForQuiz = data.sourceName
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
            }
        }
    }
}

// MARK: - JSON Parsing Helper
extension GenerationViewController {
    func parseQuizJSON(_ jsonString: String) -> [QuizQuestion] {
        var cleanString = jsonString
        if cleanString.contains("```json") {
            cleanString = cleanString.replacingOccurrences(of: "```json", with: "")
            cleanString = cleanString.replacingOccurrences(of: "```", with: "")
        }
        cleanString = cleanString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanString.data(using: .utf8) else { return [] }
        struct QuizWrapper: Codable { let questions: [QuizQuestion] }
        
        let decoder = JSONDecoder()
        if let wrapper = try? decoder.decode(QuizWrapper.self, from: data) { return wrapper.questions }
        if let array = try? decoder.decode([QuizQuestion].self, from: data) { return array }
        return []
    }
}
