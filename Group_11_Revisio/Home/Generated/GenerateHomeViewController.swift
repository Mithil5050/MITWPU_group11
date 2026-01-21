import UIKit

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCards()
        setupSteppers()
        setupDifficultyButtons()
        setupFonts()
        
        handleCardSelection(selectedCard: quizCardView, type: .quiz)
        updateDifficultyUI()
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

    private func generateDummyContent(topic: String, type: GenerationType) -> String {
        switch type {
        case .notes:
            return """
            # Notes: \(topic)
            
            1. Introduction
            \(topic) is a fundamental concept in this field. It encompasses various methodologies and practices designed to optimize performance and scalability.
            
            2. Key Concepts
            - Scalability: The ability to handle growing amounts of work.
            - Efficiency: Performing in the best possible manner with the least waste of time and effort.
            - Integration: The process of bringing together the component sub-systems into one system.
            
            3. Summary
            Remember that mastering \(topic) requires consistent practice and understanding of the underlying principles.
            """
            
        case .cheatsheet:
            return """
            # \(topic) Cheatsheet 🚀
            
            | Command | Description |
            |---------|-------------|
            | `init()` | Initializes the object |
            | `start()` | Begins the primary process |
            | `stop()`  | Halts execution immediately |
            
            Quick Formulas
            - Speed = Distance / Time
            - Efficiency = (Output / Input) * 100%
            
            Golden Rules
            1. Always validate inputs.
            2. DRY (Don't Repeat Yourself).
            3. KISS (Keep It Simple, Stupid).
            """
            
        default:
            return ""
        }
    }

    @IBAction func startCreationButtonTapped(_ sender: UIButton) {
        let topicName: String
        if let sourceItem = inputSourceData?.first {
            topicName = extractName(from: sourceItem)
        } else {
            topicName = "New Material"
        }

        let generatedContent = generateDummyContent(topic: topicName, type: selectedMaterialType)

        let newTopic = Topic(
            name: "\(topicName) \(selectedMaterialType.description)",
            lastAccessed: "Just now",
            materialType: selectedMaterialType.description,
            largeContentBody: generatedContent,
            parentSubjectName: self.contextSubjectTitle
        )
        
        DataManager.shared.addTopic(to: self.contextSubjectTitle ?? "General Study", topic: newTopic)
        
        if selectedMaterialType == .quiz {
            let payload = (topic: newTopic, sourceName: topicName)
            performSegue(withIdentifier: "HomeToQuizInstruction", sender: payload)
            
        } else if selectedMaterialType == .flashcards {
            performSegue(withIdentifier: "HomeToFlashcardView", sender: newTopic)
            
        } else if selectedMaterialType == .notes {
            performSegue(withIdentifier: "HomeToNotesView", sender: newTopic)
            
        } else if selectedMaterialType == .cheatsheet {
            performSegue(withIdentifier: "HomeToCheatsheetView", sender: newTopic)
            
        } else {
            let alert = UIAlertController(title: "Coming Soon", message: "\(selectedMaterialType.description) creation is under construction.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    private func extractName(from item: Any) -> String {
        if let content = item as? StudyContent { return content.filename }
        if let topic = item as? Topic { return topic.name }
        if let str = item as? String { return str }
        return "General Knowledge"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HomeToQuizInstruction" {
            if let dest = segue.destination as? QuizStartViewController,
               let data = sender as? (topic: Topic, sourceName: String) {
                dest.currentTopic = data.topic
                dest.quizSourceName = data.sourceName
                dest.parentSubject = self.contextSubjectTitle
            }
        }
        else if segue.identifier == "HomeToFlashcardView" {
            if let dest = segue.destination as? FlashcardsViewController,
               let topic = sender as? Topic {
                dest.currentTopic = topic
                dest.parentSubjectName = self.contextSubjectTitle
            }
        }
        else if segue.identifier == "HomeToNotesView" {
            if let dest = segue.destination as? NotesViewController,
               let topic = sender as? Topic {
                dest.currentTopic = topic
                dest.parentSubjectName = self.contextSubjectTitle
            }
        }
        else if segue.identifier == "HomeToCheatsheetView" {
            if let dest = segue.destination as? CheatsheetViewController,
               let topic = sender as? Topic {
                dest.currentTopic = topic
                dest.parentSubjectName = self.contextSubjectTitle
            }
        }
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
