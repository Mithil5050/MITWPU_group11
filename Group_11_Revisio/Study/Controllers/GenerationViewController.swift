import UIKit


// THIS MUST BE HERE TO FIX THE SCOPE ERRORS
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
// MARK: - 1. Renamed Custom Control
// Renamed to 'MaterialSelectionCard' to avoid redeclaration errors
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

// MARK: - 2. View Controller (Kept your original Class Name)
class GenerationViewController: UIViewController {
    
    // USES YOUR EXISTING ENUM AND DATA PROPERTIES
    var currentGenerationType: GenerationType = .quiz
    var sourceItems: [Any]?
    var parentSubjectName: String?
    
    // MARK: - IBOutlets (Connect these to your new UI)
    @IBOutlet weak var quizCard: MaterialSelectionCard!
    @IBOutlet weak var flashCard: MaterialSelectionCard!
    @IBOutlet weak var noteCard: MaterialSelectionCard!
    @IBOutlet weak var cheatCard: MaterialSelectionCard!
    
    @IBOutlet weak var QuizSettingsView: UIView!
    @IBOutlet weak var FlashcardSettingsView: UIView!
    @IBOutlet weak var emptySettingsPlaceholder: UIView!
    @IBOutlet weak var generateButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Default selection matches your old logic
        updateUISelection(selected: quizCard, type: .quiz)
    }
    
    private func setupUI() {
        // Professional colors to match 'Big Data' reference
        quizCard.configure(iconName: "timer", title: "Quiz", iconColor: UIColor(red: 0.45, green: 0.85, blue: 0.61, alpha: 1.0))
        flashCard.configure(iconName: "rectangle.on.rectangle.angled", title: "Flashcards", iconColor: .systemBlue)
        noteCard.configure(iconName: "doc.text", title: "Notes", iconColor: .systemOrange)
        cheatCard.configure(iconName: "list.clipboard", title: "Cheatsheet", iconColor: .systemPurple)
        
        [quizCard, flashCard, noteCard, cheatCard].forEach {
            $0?.addTarget(self, action: #selector(handleCardTap(_:)), for: .touchUpInside)
        }
        generateButton.layer.cornerRadius = 12
    }
    
    @objc func handleCardTap(_ sender: MaterialSelectionCard) {
        if sender == quizCard { updateUISelection(selected: quizCard, type: .quiz) }
        else if sender == flashCard { updateUISelection(selected: flashCard, type: .flashcards) }
        else if sender == noteCard { updateUISelection(selected: noteCard, type: .notes) }
        else if sender == cheatCard { updateUISelection(selected: cheatCard, type: .cheatsheet) }
    }
    
    private func updateUISelection(selected: MaterialSelectionCard, type: GenerationType) {
        self.currentGenerationType = type
        
        // FIX: Use a named variable instead of $0 to allow mutation
        let allCards = [quizCard, flashCard, noteCard, cheatCard]
        for card in allCards {
            // This correctly compares the card objects and sets selection
            card?.isSelected = (card === selected)
        }
        
        // Maintain your existing visibility logic
        QuizSettingsView.isHidden = (type != .quiz)
        FlashcardSettingsView.isHidden = (type != .flashcards)
        emptySettingsPlaceholder.isHidden = (type == .quiz || type == .flashcards)
        
        generateButton.setTitle("Generate \(type.description)", for: .normal)
    }

    // MARK: - THE CORE LOGIC (YOUR ORIGINAL DATA PROCESSING)
    @IBAction func generateButtonTapped(_ sender: UIButton) {
        guard let sourceItem = sourceItems?.first else { return }
        
        var topicToPass: Topic?
        var finalSpecificName: String?
        
        if let topic = sourceItem as? Topic {
            topicToPass = topic
            finalSpecificName = topic.name
        } else if let source = sourceItem as? Source {
            finalSpecificName = source.name
            if let subject = parentSubjectName,
               let materials = DataManager.shared.savedMaterials[subject]?[DataManager.materialsKey] {
                for item in materials {
                    if case .topic(let existingTopic) = item, existingTopic.name == source.name {
                        topicToPass = existingTopic
                        break
                    }
                }
            }
            if topicToPass == nil {
                topicToPass = Topic(name: source.name, lastAccessed: "Just now", materialType: currentGenerationType.description, largeContentBody: "", parentSubjectName: parentSubjectName)
            }
        }
        
        guard let topic = topicToPass, let name = finalSpecificName else { return }
        
        let updatedTopic = Topic(
            name: topic.name,
            lastAccessed: topic.lastAccessed,
            materialType: currentGenerationType.description,
            largeContentBody: topic.largeContentBody,
            parentSubjectName: topic.parentSubjectName
        )
        
        let payload = (topic: updatedTopic, sourceName: name)
        
        switch currentGenerationType {
        case .quiz: performSegue(withIdentifier: "ShowQuizInstructionsFromGen", sender: payload)
        case .notes, .cheatsheet: performSegue(withIdentifier: "ShowMaterial", sender: payload)
        case .flashcards:
            let alert = UIAlertController(title: "Coming Soon", message: "Flashcard generation is coming soon.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        case .none: break
        }
    }
    
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
        }
    }
}
