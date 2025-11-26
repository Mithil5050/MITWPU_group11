//
//  GenerationViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 26/11/25.
//

import UIKit

class GenerationViewController: UIViewController {

    private var currentChildVC: UIViewController?
    
    
    @IBOutlet weak var settingsContainerView: UIView!
  
    @IBOutlet weak var QuizButton: UIButton!
    
    @IBOutlet weak var FlashcardsButton: UIButton!
    
    @IBOutlet weak var NotesButton: UIButton!
    
    @IBOutlet weak var CheatsheetButton: UIButton!
    
    // Tracks the currently displayed settings child VC
        
        // The placeholder view where the settings panels will be displayed
        // Connect this Outlet to the Container View in the Storyboard

        override func viewDidLoad() {
            super.viewDidLoad()
            // Initialize with the Quiz settings panel visible (optional)
            displaySettings(forIdentifier: "QuizSettingsID")
            updateButtonHighlight(selectedButton: QuizButton)
        }

        // MARK: - Action Handlers for the 4 Buttons
        
        // Connect this action to the 'Touch Up Inside' event of the Quiz button
        @IBAction func quizButtonTapped(_ sender: UIButton) {
            displaySettings(forIdentifier: "QuizSettingsID")
            updateButtonHighlight(selectedButton: sender)
        }
        
        // Connect this action to the 'Touch Up Inside' event of the FlashCards button
        @IBAction func flashCardsButtonTapped(_ sender: UIButton) {
            displaySettings(forIdentifier: "FlashCardSettingsID")
            updateButtonHighlight(selectedButton: sender)
        }
        
    
    @IBAction func notesButtonTapped(_ sender: Any) {
        updateButtonHighlight(selectedButton: sender as! UIButton)
    }
    
    @IBAction func CheatsheetButtonTapped(_ sender: Any) {
        updateButtonHighlight(selectedButton: sender as! UIButton)
    }
    
    // Implement similar actions for Notes and Cheat Sheet

        // MARK: - Swapping Logic (The Core Implementation)
        
        private func displaySettings(forIdentifier identifier: String) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            // 1. Instantiate the new child view controller with correct expected type
            let newVC: UIViewController
            switch identifier {
            case "QuizSettingsID":
                guard let vc = storyboard.instantiateViewController(withIdentifier: identifier) as? QuizSettingsViewController else {
                    print("Error: Could not instantiate QuizSettingsViewController with identifier \(identifier). Check Storyboard ID and class.")
                    return
                }
                newVC = vc
            case "FlashCardSettingsID":
                guard let vc = storyboard.instantiateViewController(withIdentifier: identifier) as? FlashCardSettingsViewController else {
                    print("Error: Could not instantiate FlashCardSettingsViewController with identifier \(identifier). Check Storyboard ID and class.")
                    return
                }
                newVC = vc
            default:
                // If you add Notes/Cheatsheet later, add cases above. For now, fall back to a generic VC.
                newVC = storyboard.instantiateViewController(withIdentifier: identifier)
            }
            
            // Remove the old view controller and its view
            currentChildVC?.willMove(toParent: nil)
            currentChildVC?.view.removeFromSuperview()
            currentChildVC?.removeFromParent()
            
            // 2. Add the new view controller as a child
            self.addChild(newVC)
            
            // 3. Configure the new view to fill the container
            newVC.view.frame = settingsContainerView.bounds
            newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            settingsContainerView.addSubview(newVC.view)
            
            // 4. Finalize the child addition
            newVC.didMove(toParent: self)
            currentChildVC = newVC // Update the tracking variable
        }
    private func updateButtonHighlight(selectedButton: UIButton) {
            // Reset all buttons to the default unselected state
            let allButtons = [QuizButton, FlashcardsButton, NotesButton, CheatsheetButton]
            let defaultColor = UIColor.systemGray5 // A subtle, unselected background
            let selectedColor = UIColor.systemGray3 // A slightly darker selected background
            
            allButtons.forEach { button in
                button?.backgroundColor = defaultColor
                // You can add more visual changes here (e.g., text color, border)
            }
            
            // Highlight the selected button
            selectedButton.backgroundColor = selectedColor
        }
    }
/*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
