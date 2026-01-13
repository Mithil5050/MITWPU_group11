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
    var sourceItems: [Any]?
    var parentSubjectName: String?
    
    // MARK: - IBOutlets
    
    // Main Action Button
    @IBOutlet weak var generateButton: UIButton!
    
    
    @IBOutlet weak var QuizSettingsView: UIView!
    @IBOutlet weak var FlashcardSettingsView: UIView!
    @IBOutlet weak var emptySettingsPlaceholder: UIView!
    @IBOutlet weak var quizButton: UIButton!
    @IBOutlet weak var flashcardsButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var cheatsheetButton: UIButton!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        showSettingsView(QuizSettingsView)
        updateButtonHighlight(selectedButton: quizButton)
        
        
        updateGenerateButton(for: .quiz)
    }
    
    // MARK: - Private Configuration Methods
    
   
    private func showSettingsView(_ viewToShow: UIView) {
        
        let allSettingsViews: [UIView?] = [
            QuizSettingsView,
            FlashcardSettingsView,
            emptySettingsPlaceholder
        ]
        
        
        for view in allSettingsViews {
            view?.isHidden = true
        }
        
        
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
            title = "Generate \(type.description)"
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
        
        // Semantic Colors for Dark/Light Mode support
        let unselectedBackground = UIColor.systemGray6
        let selectedBackground = UIColor.systemGray4
        let unselectedTitleColor = UIColor.secondaryLabel // Uses system gray text
        let selectedTitleColor = UIColor.label          // Uses primary text color
        
        for button in allButtons {
            let isSelected = (button === selectedButton)
            
            // Wrap in an animation block for a smooth transition
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                if isSelected {
                    button?.backgroundColor = selectedBackground
                    button?.setTitleColor(selectedTitleColor, for: .normal)
                    button?.tintColor = selectedTitleColor
                    
                    // 1. Add a slight "Pop" scale effect
                    button?.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    
                    // 2. Add a subtle border to define the selection
                    button?.layer.borderWidth = 2.0
                    button?.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
                    
                } else {
                    button?.backgroundColor = unselectedBackground
                    button?.setTitleColor(unselectedTitleColor, for: .normal)
                    button?.tintColor = unselectedTitleColor
                    
                    // 3. Reset scale and remove border
                    button?.transform = .identity
                    button?.layer.borderWidth = 0
                }
                
                button?.layer.cornerRadius = 12
            }
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
            
            var topicToPass: Topic?
            var finalSpecificName: String?
            
            // 2. Identify the source and attempt to fetch existing data from DataManager
            if let topic = sourceItem as? Topic {
                // If selecting an existing topic from the library list
                topicToPass = topic
                finalSpecificName = topic.name
            } else if let source = sourceItem as? Source {
                // If selecting a raw Source (PDF/Link)
                finalSpecificName = source.name
                
                // SEARCH: Try to find the hardcoded Topic in your library that matches the source name
                if let subject = parentSubjectName,
                   let materials = DataManager.shared.savedMaterials[subject]?[DataManager.materialsKey] {
                    for item in materials {
                        if case .topic(let existingTopic) = item, existingTopic.name == source.name {
                            topicToPass = existingTopic
                            break
                        }
                    }
                }
                
                // FALLBACK: If not found in library, create a blank placeholder
                if topicToPass == nil {
                    topicToPass = Topic(
                        name: source.name,
                        lastAccessed: "Just now",
                        materialType: currentGenerationType.description,
                        largeContentBody: "",
                        parentSubjectName: parentSubjectName,
                        notesContent: nil,
                        cheatsheetContent: nil
                    )
                }
            }
            
            // 3. Validation and Payload preparation
            guard let topic = topicToPass, let name = finalSpecificName else { return }
            
            // RECONSTRUCTION: Create a fresh copy to update 'materialType' (Fixes the 'let' constant error)
            let updatedTopic = Topic(
                name: topic.name,
                lastAccessed: topic.lastAccessed,
                materialType: currentGenerationType.description, // Updates to "Notes" or "Cheatsheet"
                largeContentBody: topic.largeContentBody,
                parentSubjectName: topic.parentSubjectName,
                notesContent: topic.notesContent,
                cheatsheetContent: topic.cheatsheetContent
            )
            
            let payload = (topic: updatedTopic, sourceName: name)

            // 4. Navigation
            switch currentGenerationType {
            case .quiz:
                performSegue(withIdentifier: "ShowQuizInstructionsFromGen", sender: payload)
                
            case .notes, .cheatsheet:
                performSegue(withIdentifier: "ShowMaterial", sender: payload)
                
            case .flashcards:
                showComingSoonAlert()
                
            case .none:
                break
            }
    }
    private func showComingSoonAlert() {
        let alert = UIAlertController(title: "Coming Soon", message: "Flashcard generation is currently in development for Group 11 Revision.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let data = sender as? (topic: Topic, sourceName: String) else { return }
        
        if segue.identifier == "ShowQuizInstructionsFromGen" {
            if let instructionVC = segue.destination as? InstructionViewController {
                instructionVC.quizTopic = data.topic
                instructionVC.sourceNameForQuiz = data.sourceName
                instructionVC.parentSubjectName = self.parentSubjectName
            }
        }
       
        else if segue.identifier == "ShowMaterial" {
            if let materialVC = segue.destination as? MaterialGenerationViewController {
                materialVC.contentData = data.topic
                materialVC.parentSubjectName = self.parentSubjectName
                
                // Pass the type so the title and content switch correctly
                materialVC.materialType = self.currentGenerationType.description
            }
        }
    }
}
