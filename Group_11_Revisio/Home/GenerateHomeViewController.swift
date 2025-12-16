//
//  GenerateHomeViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 15/12/25.
//

import UIKit

// Reusing the GenerationType enum as it represents the core model logic.
// enum GenerationType is already defined in GenerationViewController.swift.
// For simplicity, it is assumed this file will be part of the same project target.

class GenerateHomeViewController: UIViewController {

    // MARK: - Data Properties
    // Renamed for context: 'generation' -> 'material'
    var selectedMaterialType: GenerationType = .none
    var inputSourceData: [Any]? // Data source (e.g., Topic or Source objects)
    var contextSubjectTitle: String? // Contextual name for the navigation bar/context

    // MARK: - IBOutlets (All renamed: 'generateButton' -> 'creationButton', 'SettingsView' -> 'ConfigView', 'Button' -> 'TabButton')

    // Main Action Button
    @IBOutlet weak var startCreationButton: UIButton!

    // Settings container views (These should overlap in the Storyboard)
    @IBOutlet weak var quizConfigurationView: UIView!
    @IBOutlet weak var flashcardConfigurationView: UIView!
    @IBOutlet weak var defaultConfigurationPlaceholder: UIView! // Used for types without custom settings (Notes/Cheatsheet)

    // Top Tab Buttons (Function as a segment control)
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

        // Initial button state
        updateStartCreationButton(for: .quiz)
    }

    // MARK: - Private Configuration Methods (All renamed)

    /**
     Controls which material configuration view is visible to the user.
     - Parameter viewToShow: The specific settings container view to display.
     */
    private func displayConfigurationView(_ viewToShow: UIView) {
        // 1. Create an array of all settings views
        let allConfigViews: [UIView?] = [
            quizConfigurationView,
            flashcardConfigurationView,
            defaultConfigurationPlaceholder
        ]

        // 2. Hide all views
        for view in allConfigViews {
            view?.isHidden = true
        }

        // 3. Show the selected view
        viewToShow.isHidden = false
    }

    /**
     Updates the text and enabled state of the primary creation button.
     - Parameter type: The selected GenerationType.
     */
    private func updateStartCreationButton(for type: GenerationType) {
        self.selectedMaterialType = type

        let title: String
        let isEnabled: Bool

        if type == .none {
            title = "Start Creation"
            isEnabled = false
        } else {
            // Uses the CustomStringConvertible extension from GenerationType
            title = "Create \(type.description)"
            isEnabled = true
        }

        startCreationButton.setTitle(title, for: .normal)
        startCreationButton.isEnabled = isEnabled

        // Apply professional, modern iOS 26 visual state
        startCreationButton.alpha = isEnabled ? 1.0 : 0.5
    }

    /**
     Manages the visual selection state of the tab buttons (iOS-style segmented appearance).
     - Parameter selectedButton: The button that was just tapped.
     */
    private func styleSelectedTabButton(selectedButton: UIButton) {
        let allButtons: [UIButton?] = [
            quizTabButton,
            flashcardsTabButton,
            notesTabButton,
            cheatsheetTabButton
        ]

        // --- Define the Gray Aesthetic Colors (Based on iOS Semantic Colors) ---
        let unselectedBackground = UIColor.systemGray6
        let selectedBackground = UIColor.systemGray4
        let unselectedTitleColor = UIColor.secondaryLabel
        let selectedTitleColor = UIColor.label
        let unselectedIconTint = UIColor.secondaryLabel
        let selectedIconTint = UIColor.label

        for button in allButtons {
            let isSelected = (button === selectedButton)

            if isSelected {
                // SELECTED STATE: Subtle highlight, strong text/icon.
                button?.backgroundColor = selectedBackground
                button?.setTitleColor(selectedTitleColor, for: .normal)
                button?.tintColor = selectedIconTint
            } else {
                // UNSELECTED STATE: Neutral background, secondary text/icon.
                button?.backgroundColor = unselectedBackground
                button?.setTitleColor(unselectedTitleColor, for: .normal)
                button?.tintColor = unselectedIconTint
            }

            // Apply standard iOS-style corner radius
            button?.layer.cornerRadius = 12
        }
    }

    // MARK: - Action Handlers (Button Taps) (All renamed)

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

    @IBAction func startCreationButtonTapped(_ sender: UIButton) {

        // 1. Validate source data availability
        guard let _ = inputSourceData?.first else {
            print("Error: No source item available to generate material from.")
            return
        }

        // 2. Log creation attempt (Segue logic removed)
        switch selectedMaterialType {
        case .quiz:
            print("Action: Attempted to start Quiz creation. (Segue removed)")
            performSegue(withIdentifier: "HomeToQuizInstruction", sender: nil)

        case .flashcards:
            print("Action: Attempted to start Flashcard creation. (Segue removed)")
            performSegue(withIdentifier: "HomeToFlashcardView", sender: nil)

        case .notes:
            print("Action: Attempted to start Notes creation. (Segue removed)")
            performSegue(withIdentifier: "HomeToNotesView", sender: nil)

        case .cheatsheet:
            print("Action: Attempted to start Cheatsheet creation. (Segue removed)")
            performSegue(withIdentifier: "HomeToCheatSheetView", sender: nil)
            

        case .none:
            print("Error: No material type selected.")
        }
    }

    // MARK: - Navigation
    // The prepare(for segue:...) method is removed as requested.

}
