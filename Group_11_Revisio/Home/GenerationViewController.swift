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

class GenerationViewController: UIViewController {
    
    var currentGenerationType: GenerationType = .none
    var sourceItems: [Any]?
    var parentSubjectName: String?
    
    @IBOutlet weak var generateButton: UIButton!
    
    
    // Settings container views
    @IBOutlet weak var QuizSettingsView: UIView!
    @IBOutlet weak var FlashcardSettingsView: UIView!
    
    @IBOutlet weak var emptySettingsPlaceholder: UIView!
    
    // Top tab buttons (connect these in Interface Builder)
    @IBOutlet weak var quizButton: UIButton!
    @IBOutlet weak var flashcardsButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var cheatsheetButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Quiz settings by default
        showSettingsView(QuizSettingsView)
        updateButtonHighlight(selectedButton: quizButton)
        generateButton.isEnabled = false
        generateButton.alpha = 0.5
        // Ensure only Quiz is visible initially
        //        QuizSettingsView.isHidden = false
        //        FlashcardSettingsView.isHidden = true
    }
    
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
        
        // Update button text and state
        let title: String
        if type == .none {
            title = "Generate"
            generateButton.isEnabled = false
            generateButton.alpha = 0.5
        } else {
            title = "Generate \(String(describing: type).capitalized)"
            generateButton.isEnabled = true
            generateButton.alpha = 1.0
        }
        generateButton.setTitle(title, for: .normal)
    }
    // Updates visual state for the tab buttons
    private func updateButtonHighlight(selectedButton: UIButton) {
        let allButtons: [UIButton?] = [
            quizButton,
            flashcardsButton,
            notesButton,
            cheatsheetButton
        ]
        
        // --- Define the Gray Aesthetic Colors ---
        let unselectedBackground = UIColor.systemGray6 // Very light gray card
        let selectedBackground = UIColor.systemGray4   // Medium gray for subtle highlight
        let unselectedTitleColor = UIColor.darkGray    // Dark text for contrast
        let selectedTitleColor = UIColor.black         // Black text/icon for selected state
        let unselectedIconTint = UIColor.darkGray      // Dark gray icon color
        let selectedIconTint = UIColor.black           // Black icon color
        
        for button in allButtons {
            let isSelected = (button === selectedButton)
            
            if isSelected {
                // SELECTED STATE: Medium gray background, black text/icon.
                button?.backgroundColor = selectedBackground
                button?.setTitleColor(selectedTitleColor, for: .normal)
                button?.tintColor = selectedIconTint // Use tintColor to control the icon color
            } else {
                // UNSELECTED STATE: Very light gray background, dark gray text/icon.
                button?.backgroundColor = unselectedBackground
                button?.setTitleColor(unselectedTitleColor, for: .normal)
                button?.tintColor = unselectedIconTint
            }
            
            // Optional: Add corner radius if not set in Storyboard (recommended for cards)
            button?.layer.cornerRadius = 12
        }
    }
    // MARK: - Action Handlers
    
    @IBAction func quizButtonTapped(_ sender: UIButton) {
        showSettingsView(QuizSettingsView) // Show Quiz view
        updateButtonHighlight(selectedButton: sender)
        updateGenerateButton(for: .quiz) // ⬅️ NEW
    }
    
    @IBAction func flashCardsButtonTapped(_ sender: UIButton) {
        showSettingsView(FlashcardSettingsView) // Show Flashcard view
        updateButtonHighlight(selectedButton: sender)
        updateGenerateButton(for: .flashcards) // ⬅️ NEW
    }
    
    @IBAction func notesButtonTapped(_ sender: UIButton) {
        showSettingsView(emptySettingsPlaceholder) // Add when you have a Notes view
        updateButtonHighlight(selectedButton: sender)
        updateGenerateButton(for: .notes) // ⬅️ NEW
    }
    
    @IBAction func cheatsheetButtonTapped(_ sender: UIButton) {
        showSettingsView(emptySettingsPlaceholder) // Add when you have a Cheat Sheet view
        updateButtonHighlight(selectedButton: sender)
        updateGenerateButton(for: .cheatsheet) // ⬅️ NEW
    }
    @IBAction func generateButtonTapped(_ sender: UIButton) {
        
        guard let sourceItem = sourceItems?.first else {
            print("Error: No source item available to generate quiz from.")
            return
        }
        
        switch currentGenerationType {
        case .quiz:
            print("Initiating Quiz Generation and segue to Instructions...")
            
            let topicToPass: Topic?
            
            if let topic = sourceItem as? Topic {
                // Case 1: Source item is already a Topic
                topicToPass = topic
                
            } else if let source = sourceItem as? Source {
                // Case 2: Source item is a Source, create a dummy Topic structure
                topicToPass = Topic(name: source.name, lastAccessed: "N/A", materialType: "Quiz")
                
            } else {
                topicToPass = nil
            }
            
            if let topic = topicToPass {
                // ⭐️ This performs the segue! ⭐️
                performSegue(withIdentifier: "ShowQuizInstructionsFromGen", sender: topic)
            } else {
                print("Error: Could not create valid Topic data to start quiz.")
            }
            
        case .flashcards, .notes, .cheatsheet, .none:
            // Other generation types or error handling
            print("Generation type \(currentGenerationType) not yet fully implemented for segue.")
            break
        }
        
        
    }
    // GenerationViewController.swift

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ShowQuizInstructionsFromGen" {
            
            guard let topicData = sender as? Topic else {
                print("Prepare Error: Sender was not a Topic.")
                return
            }

            if let instructionVC = segue.destination as? InstructionViewController {
                
                // Pass the Topic data to the Instruction Screen
                instructionVC.quizTopic = topicData
                
                // Pass the parent subject name for context
                instructionVC.parentSubjectName = self.parentSubjectName
            }
        }
    }
}
 
   
