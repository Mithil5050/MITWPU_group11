//
//  GenerateHomeViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 15/12/25.
//  Updated: Standard Navigation (AI Removed)
//

import UIKit

class GenerateHomeViewController: UIViewController {

    // MARK: - Data Properties
    var selectedMaterialType: GenerationType = .none
    var inputSourceData: [Any]? // Data source passed from previous screen
    var contextSubjectTitle: String? // Contextual name (e.g., "Calculus")

    // MARK: - IBOutlets
    @IBOutlet weak var startCreationButton: UIButton!

    // Settings container views
    @IBOutlet weak var quizConfigurationView: UIView!
    @IBOutlet weak var flashcardConfigurationView: UIView!
    @IBOutlet weak var defaultConfigurationPlaceholder: UIView!

    // Top Tab Buttons
    @IBOutlet weak var quizTabButton: UIButton!
    @IBOutlet weak var flashcardsTabButton: UIButton!
    @IBOutlet weak var notesTabButton: UIButton!
    @IBOutlet weak var cheatsheetTabButton: UIButton!

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup initial state: Select Quiz by default
        displayConfigurationView(quizConfigurationView)
        styleSelectedTabButton(selectedButton: quizTabButton)
        updateStartCreationButton(for: .quiz)
    }

    // MARK: - Configuration Methods
    private func displayConfigurationView(_ viewToShow: UIView) {
        let allConfigViews: [UIView?] = [
            quizConfigurationView,
            flashcardConfigurationView,
            defaultConfigurationPlaceholder
        ]
        allConfigViews.forEach { $0?.isHidden = true }
        viewToShow.isHidden = false
    }

    private func updateStartCreationButton(for type: GenerationType) {
        self.selectedMaterialType = type
        
        let title = (type == .none) ? "Start Creation" : "Create \(type.description)"
        let isEnabled = (type != .none)
        
        startCreationButton.setTitle(title, for: .normal)
        startCreationButton.isEnabled = isEnabled
        startCreationButton.alpha = isEnabled ? 1.0 : 0.5
    }

    private func styleSelectedTabButton(selectedButton: UIButton) {
        let allButtons = [quizTabButton, flashcardsTabButton, notesTabButton, cheatsheetTabButton]
        
        // Modern Gray Aesthetic Colors
        let unselectedBackground = UIColor.systemGray6
        let selectedBackground = UIColor.systemGray4
        let unselectedTitleColor = UIColor.secondaryLabel
        let selectedTitleColor = UIColor.label
        
        for button in allButtons {
            guard let btn = button else { continue }
            let isSelected = (btn === selectedButton)
            
            btn.backgroundColor = isSelected ? selectedBackground : unselectedBackground
            btn.setTitleColor(isSelected ? selectedTitleColor : unselectedTitleColor, for: .normal)
            btn.tintColor = isSelected ? selectedTitleColor : unselectedTitleColor
            btn.layer.cornerRadius = 12
        }
    }

    // MARK: - Actions (Tab Taps)
    @IBAction func quizTabButtonTapped(_ sender: UIButton) {
        displayConfigurationView(quizConfigurationView)
        styleSelectedTabButton(selectedButton: sender)
        updateStartCreationButton(for: .quiz)
    }

    @IBAction func flashcardsTabButtonTapped(_ sender: UIButton) {
        displayConfigurationView(flashcardConfigurationView)
        styleSelectedTabButton(selectedButton: sender)
        updateStartCreationButton(for: .flashcards)
    }

    @IBAction func notesTabButtonTapped(_ sender: UIButton) {
        displayConfigurationView(defaultConfigurationPlaceholder)
        styleSelectedTabButton(selectedButton: sender)
        updateStartCreationButton(for: .notes)
    }

    @IBAction func cheatsheetTabButtonTapped(_ sender: UIButton) {
        displayConfigurationView(defaultConfigurationPlaceholder)
        styleSelectedTabButton(selectedButton: sender)
        updateStartCreationButton(for: .cheatsheet)
    }

    // MARK: - Main Action (Normal Navigation)
    @IBAction func startCreationButtonTapped(_ sender: UIButton) {
        
        // 1. Determine Topic Name
        let topicName: String
        if let sourceItem = inputSourceData?.first {
            topicName = extractName(from: sourceItem)
        } else {
            // Fallback if nothing selected (Optional: You could show an alert here)
            topicName = "New Material"
        }

        // 2. Create the Topic Object (Placeholder Content)
        // Since we aren't generating AI content, 'largeContentBody' is empty.
        let newTopic = Topic(
            name: "\(topicName) \(selectedMaterialType.description)",
            lastAccessed: "Just now",
            materialType: selectedMaterialType.description,
            largeContentBody: "", // Empty content
            parentSubjectName: self.contextSubjectTitle
        )
        
        // 3. Save to DataManager (So it appears in lists)
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
