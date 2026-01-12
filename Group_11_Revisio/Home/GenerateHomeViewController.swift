//
//  GenerateHomeViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 15/12/25.
//  Updated: Vertical Stack for Icon Top / Text Bottom Layout
//

import UIKit

// MARK: - Custom Tappable Card View
@IBDesignable
class TappableCardView: UIControl {
    
    private let stackView = UIStackView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    
    // Default background (unselected)
    private var defaultBackgroundColor: UIColor = .secondarySystemGroupedBackground
    // Selected/Highlighted background
    private var highlightBackgroundColor: UIColor = .systemGray5
    
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
        
        // Icon Setup (Larger for Vertical Layout)
        iconImageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 48), // Increased size
            iconImageView.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        // Title Setup
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center // Center text below icon
        
        // Stack Setup - VERTICAL
        stackView.axis = .vertical
        stackView.spacing = 8 // Space between Icon and Text
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false // Let the UIControl handle touches
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        
        addSubview(stackView)
        
        // Constraints: Center the stack in the view
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            // Optional: Ensure it doesn't touch edges on very small screens
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -8)
        ])
    }
    
    // Updated: Accepts UIColor directly
    func configure(iconName: String, title: String, highlightColor: UIColor) {
        // Use a lighter weight for a clean look
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .light)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        titleLabel.text = title
        iconImageView.tintColor = .systemBlue
        
        self.highlightBackgroundColor = highlightColor
    }
    
    // Updates appearance when selected
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = isSelected ? highlightBackgroundColor : defaultBackgroundColor
            // Optional: Change border if desired
            self.layer.borderWidth = isSelected ? 2 : 0
            self.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : nil
        }
    }
    
    // Updates appearance when pressed
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
                // If not selected, show highlight color briefly
                if !self.isSelected {
                    self.backgroundColor = self.isHighlighted ? self.highlightBackgroundColor : self.defaultBackgroundColor
                }
            }
        }
    }
}

// MARK: - View Controller
class GenerateHomeViewController: UIViewController {

    // MARK: - Properties
    var selectedMaterialType: GenerationType = .none
    var inputSourceData: [Any]?
    var contextSubjectTitle: String?

    // MARK: - IBOutlets
    @IBOutlet weak var startCreationButton: UIButton!
    
    // IMPORTANT: Ensure these are Class: TappableCardView in Storyboard Identity Inspector
    @IBOutlet weak var quizCardView: TappableCardView!
    @IBOutlet weak var flashcardsCardView: TappableCardView!
    @IBOutlet weak var notesCardView: TappableCardView!
    @IBOutlet weak var cheatsheetCardView: TappableCardView!

    // Settings Containers
    @IBOutlet weak var quizConfigurationView: UIView!
    @IBOutlet weak var flashcardConfigurationView: UIView!
    @IBOutlet weak var defaultConfigurationPlaceholder: UIView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCards()
        
        // Initial State: Select Quiz by default
        handleCardSelection(selectedCard: quizCardView, type: .quiz)
    }

    private func setupCards() {
        // 1. Configure Visuals with specific RGB values
        
        // Quiz: F0FFDB (240, 255, 219)
        // Icon: "timer" or "clock" looks closer to your screenshot than checkmark
        quizCardView.configure(
            iconName: "timer",
            title: "Quiz",
            highlightColor: UIColor(red: 240/255, green: 255/255, blue: 219/255, alpha: 1.0)
        )
        
        // Flashcards: E3EFFB (227, 239, 251)
        flashcardsCardView.configure(
            iconName: "rectangle.on.rectangle.angled",
            title: "Flashcards",
            highlightColor: UIColor(red: 227/255, green: 239/255, blue: 251/255, alpha: 1.0)
        )
        
        // Notes: FAFBD1 (250, 251, 209)
        notesCardView.configure(
            iconName: "doc.text",
            title: "Notes",
            highlightColor: UIColor(red: 250/255, green: 251/255, blue: 209/255, alpha: 1.0)
        )
        
        // Cheatsheet: D9D1FF (217, 209, 255)
        cheatsheetCardView.configure(
            iconName: "list.clipboard",
            title: "Cheatsheet",
            highlightColor: UIColor(red: 217/255, green: 209/255, blue: 255/255, alpha: 1.0)
        )
        
        // 2. Add Targets (Wire up touch events)
        quizCardView.addTarget(self, action: #selector(quizTapped), for: .touchUpInside)
        flashcardsCardView.addTarget(self, action: #selector(flashcardsTapped), for: .touchUpInside)
        notesCardView.addTarget(self, action: #selector(notesTapped), for: .touchUpInside)
        cheatsheetCardView.addTarget(self, action: #selector(cheatsheetTapped), for: .touchUpInside)
        
        // Style Start Button
        startCreationButton.layer.cornerRadius = 12
    }

    // MARK: - Selection Logic
    
    private func handleCardSelection(selectedCard: TappableCardView, type: GenerationType) {
        // 1. Update State
        self.selectedMaterialType = type
        
        // 2. Update Visuals (Only one card selected at a time)
        let allCards = [quizCardView, flashcardsCardView, notesCardView, cheatsheetCardView]
        allCards.forEach { card in
            card?.isSelected = (card === selectedCard)
        }
        
        // 3. Update Settings View Visibility
        quizConfigurationView.isHidden = (type != .quiz)
        flashcardConfigurationView.isHidden = (type != .flashcards)
        
        // Notes & Cheatsheet share the placeholder view
        let isPlaceholderVisible = (type == .notes || type == .cheatsheet)
        defaultConfigurationPlaceholder.isHidden = !isPlaceholderVisible
        
        // 4. Update Button Text
        let title = (type == .none) ? "Start Creation" : "Create \(type.description)"
        startCreationButton.setTitle(title, for: .normal)
        startCreationButton.isEnabled = true
        startCreationButton.alpha = 1.0
    }

    // MARK: - Actions (Tapped Handlers)
    @objc func quizTapped() { handleCardSelection(selectedCard: quizCardView, type: .quiz) }
    @objc func flashcardsTapped() { handleCardSelection(selectedCard: flashcardsCardView, type: .flashcards) }
    @objc func notesTapped() { handleCardSelection(selectedCard: notesCardView, type: .notes) }
    @objc func cheatsheetTapped() { handleCardSelection(selectedCard: cheatsheetCardView, type: .cheatsheet) }

    // MARK: - Main Action (Navigation Logic)
    @IBAction func startCreationButtonTapped(_ sender: UIButton) {
        
        // 1. Determine Topic Name
        let topicName: String
        if let sourceItem = inputSourceData?.first {
            topicName = extractName(from: sourceItem)
        } else {
            topicName = "New Material"
        }

        // 2. Create Topic Placeholder
        let newTopic = Topic(
            name: "\(topicName) \(selectedMaterialType.description)",
            lastAccessed: "Just now",
            materialType: selectedMaterialType.description,
            largeContentBody: "", // Empty content
            parentSubjectName: self.contextSubjectTitle
        )
        
        // 3. Save to DataManager
        DataManager.shared.addTopic(to: self.contextSubjectTitle ?? "General Study", topic: newTopic)
        
        // 4. Navigate based on Type
        if selectedMaterialType == .quiz {
            // Pack data for Quiz Instruction screen
            let payload = (topic: newTopic, sourceName: topicName)
            performSegue(withIdentifier: "HomeToQuizInstruction", sender: payload)
            
        } else if selectedMaterialType == .flashcards {
            // Navigate to Flashcards
            performSegue(withIdentifier: "HomeToFlashcardView", sender: newTopic)
            
        } else {
            // Fallback for Notes/Cheatsheet
            let alert = UIAlertController(title: "Coming Soon", message: "\(selectedMaterialType.description) creation is under construction.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    // MARK: - Helper Methods
    private func extractName(from item: Any) -> String {
        if let content = item as? StudyContent { return content.filename }
        if let topic = item as? Topic { return topic.name }
        if let str = item as? String { return str }
        return "General Knowledge"
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Quiz Segue
        if segue.identifier == "HomeToQuizInstruction" {
            if let dest = segue.destination as? InstructionViewController,
               let data = sender as? (topic: Topic, sourceName: String) {
                
                dest.quizTopic = data.topic
                dest.sourceNameForQuiz = data.sourceName
                dest.parentSubjectName = self.contextSubjectTitle
            }
        }
        
        // Flashcard Segue
        else if segue.identifier == "HomeToFlashcardView" {
            if let dest = segue.destination as? FlashcardsViewController,
               let topic = sender as? Topic {
                
                dest.currentTopic = topic
                dest.parentSubjectName = self.contextSubjectTitle
            }
        }
    }
}
