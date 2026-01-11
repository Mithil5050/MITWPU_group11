//
//  GenerateHomeViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 15/12/25.
//

import UIKit

class GenerateHomeViewController: UIViewController {

    // MARK: - Data Properties
    var selectedMaterialType: GenerationType = .none
    var inputSourceData: [Any]? // Data source (e.g., Topic or Source objects)
    var contextSubjectTitle: String? // Contextual name for the navigation bar/context

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

    // MARK: - Main Action (Start Creation)
    @IBAction func startCreationButtonTapped(_ sender: UIButton) {
        
        // 1. Validation (Temporarily disabled for testing navigation)
        // If 'inputSourceData' is nil, the code below will still run so you can see the next screen.
        /*
        guard let _ = inputSourceData?.first else {
             print("Error: No source item available to generate material from.")
             return
        }
        */

        // 2. Perform Segue based on selection
        switch selectedMaterialType {
        case .quiz:
            print("Navigating to Quiz...")
            performSegue(withIdentifier: "HomeToQuizInstruction", sender: nil)
            
        case .flashcards:
            print("Navigating to Flashcards...")
            performSegue(withIdentifier: "HomeToFlashcardView", sender: nil)
            
        case .notes:
            print("Navigating to Notes...")
            performSegue(withIdentifier: "HomeToNotesView", sender: nil)
            
        case .cheatsheet:
            print("Navigating to Cheatsheet...")
            performSegue(withIdentifier: "HomeToCheatSheetView", sender: nil)
            
        case .none:
            print("Error: No material type selected.")
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // This is where you pass data to the next screen.
        // Ensure your destination View Controllers have a variable like 'sourceData' to receive it.
        
        if segue.identifier == "HomeToQuizInstruction" {
            // let destination = segue.destination as? QuizViewController
            // destination?.sourceData = self.inputSourceData
        }
        else if segue.identifier == "HomeToFlashcardView" {
            // let destination = segue.destination as? FlashcardViewController
            // destination?.sourceData = self.inputSourceData
        }
        else if segue.identifier == "HomeToNotesView" {
            // let destination = segue.destination as? NotesViewController
            // destination?.sourceData = self.inputSourceData
        }
        // Add other cases as needed
    }
}
