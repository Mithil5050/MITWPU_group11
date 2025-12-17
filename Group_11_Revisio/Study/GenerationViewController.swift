//
//  GenerationViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 27/11/25.
//

import UIKit


enum GenerationType {
    case quiz
    case flashcards
    case notes
    case cheatsheet
    case none // Default state
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


class GenerationViewController: UIViewController {
    
    // MARK: - Data Properties
    var currentGenerationType: GenerationType = .none
    var sourceItems: [Any]? // Data source (e.g., Topic or Source objects)
    var parentSubjectName: String? // Contextual name for the navigation bar/context
    
    // MARK: - IBOutlets
    
    // Main Action Button
    @IBOutlet weak var generateButton: UIButton!
    
    // Settings container views (These should overlap in the Storyboard)
    @IBOutlet weak var QuizSettingsView: UIView!
    @IBOutlet weak var FlashcardSettingsView: UIView!
    @IBOutlet weak var emptySettingsPlaceholder: UIView! // Used for types without custom settings (Notes/Cheatsheet)
    
    // Top Tab Buttons (Function as a segment control)
    @IBOutlet weak var quizButton: UIButton!
    @IBOutlet weak var flashcardsButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var cheatsheetButton: UIButton!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup initial state: Select Quiz by default
        showSettingsView(QuizSettingsView)
        updateButtonHighlight(selectedButton: quizButton)
        
        // Initial button state (should be updated immediately by updateGenerateButton)
        updateGenerateButton(for: .quiz)
    }
    
    // MARK: - Private Configuration Methods
    
    /**
     Controls which settings view is visible to the user.
     - Parameter viewToShow: The specific settings container view to display.
     */
    private func showSettingsView(_ viewToShow: UIView) {
        // 1. Create an array of all settings views
        let allSettingsViews: [UIView?] = [
            QuizSettingsView,
            FlashcardSettingsView,
            emptySettingsPlaceholder
        ]
        
        // 2. Hide all views
        for view in allSettingsViews {
            view?.isHidden = true
        }
        
        // 3. Show the selected view
        viewToShow.isHidden = false
    }
    
    
    private func updateGenerateButton(for type: GenerationType) {
        self.currentGenerationType = type
        
        let title: String
        let isEnabled: Bool
        
        if type == .none {
            title = "Generate"
            isEnabled = false
        } else {
            title = "Generate \(type.description)" // Uses the CustomStringConvertible extension
            isEnabled = true
        }
        
        generateButton.setTitle(title, for: .normal)
        generateButton.isEnabled = isEnabled
        
        // Apply professional, modern iOS 26 visual state
        generateButton.alpha = isEnabled ? 1.0 : 0.5
    }
    
    
    private func updateButtonHighlight(selectedButton: UIButton) {
        let allButtons: [UIButton?] = [
            quizButton,
            flashcardsButton,
            notesButton,
            cheatsheetButton
        ]
        
        
        let unselectedBackground = UIColor.systemGray6 // Very light gray card
        let selectedBackground = UIColor.systemGray4   // Medium gray for subtle highlight
        let unselectedTitleColor = UIColor.darkGray    // Dark text for contrast
        let selectedTitleColor = UIColor.label         // Black text/icon for selected state
        let unselectedIconTint = UIColor.darkGray      // Dark gray icon color
        let selectedIconTint = UIColor.label           // Black icon color
        
        for button in allButtons {
            let isSelected = (button === selectedButton)
            
            if isSelected {
                // SELECTED STATE: Medium gray background, black text/icon.
                button?.backgroundColor = selectedBackground
                button?.setTitleColor(selectedTitleColor, for: .normal)
                button?.tintColor = selectedIconTint // Controls the icon color
            } else {
                // UNSELECTED STATE: Very light gray background, dark gray text/icon.
                button?.backgroundColor = unselectedBackground
                button?.setTitleColor(unselectedTitleColor, for: .normal)
                button?.tintColor = unselectedIconTint
            }
            
            // Apply standard iOS-style corner radius
            button?.layer.cornerRadius = 12
        }
    }
    
    // MARK: - Action Handlers (Button Taps)
    
    @IBAction func quizButtonTapped(_ sender: UIButton) {
        showSettingsView(QuizSettingsView)
        updateButtonHighlight(selectedButton: sender)
        updateGenerateButton(for: .quiz)
    }
    
    @IBAction func flashCardsButtonTapped(_ sender: UIButton) {
        showSettingsView(FlashcardSettingsView)
        updateButtonHighlight(selectedButton: sender)
        updateGenerateButton(for: .flashcards)
    }
    
    @IBAction func notesButtonTapped(_ sender: UIButton) {
        showSettingsView(emptySettingsPlaceholder)
        updateButtonHighlight(selectedButton: sender)
        updateGenerateButton(for: .notes)
    }
    
    @IBAction func cheatsheetButtonTapped(_ sender: UIButton) {
        showSettingsView(emptySettingsPlaceholder)
        updateButtonHighlight(selectedButton: sender)
        updateGenerateButton(for: .cheatsheet)
    }
    
    @IBAction func generateButtonTapped(_ sender: UIButton) {
        
        guard let sourceItem = sourceItems?.first else { return }
        
        var finalSpecificName: String?
        let topicToPass: Topic?
        
        if let topic = sourceItem as? Topic {
            topicToPass = topic
            finalSpecificName = topic.name
        } else if let source = sourceItem as? Source {
            // 🛑 FIX: Use the actual source name (e.g., "Hadoop Doc")
            finalSpecificName = source.name
            
            // Create the topic using the specific source name
            topicToPass = Topic(name: source.name,
                                lastAccessed: "N/A",
                                materialType: currentGenerationType.description)
        } else {
            topicToPass = nil
        }
        
        if let topic = topicToPass, let name = finalSpecificName {
            // 🛑 Pack BOTH into a tuple sender
            let payload = (topic: topic, sourceName: name)
            
            if currentGenerationType == .quiz {
                performSegue(withIdentifier: "ShowQuizInstructionsFromGen", sender: payload)
            }
        }
    }
    
    // MARK: - Navigation
    
    /**
     Prepares the destination view controller before the transition.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // 🛑 Unpack the tuple payload
        guard let data = sender as? (topic: Topic, sourceName: String) else { return }
        
        if segue.identifier == "ShowQuizInstructionsFromGen" {
            if let instructionVC = segue.destination as? InstructionViewController {
                instructionVC.quizTopic = data.topic
                instructionVC.sourceNameForQuiz = data.sourceName // This will now be "Hadoop Doc"
                instructionVC.parentSubjectName = self.parentSubjectName
            }
        }
    }
}
