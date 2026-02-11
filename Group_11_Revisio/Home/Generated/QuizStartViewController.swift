//
//  QuizStartViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 11/12/25.
//

import UIKit

class QuizStartViewController: UIViewController {

    // MARK: - Data Variables
    var currentTopic: Topic?
    var parentSubject: String?
    var quizSourceName: String?
    
    // MARK: - Outlets
    @IBOutlet weak var quizTitleLabel: UILabel!
    @IBOutlet weak var rulesTextView: UITextView!
    @IBOutlet weak var beginButton: UIButton!
    @IBOutlet weak var saveAndCloseButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = false
        
        configureUI()
        designButtons()
    }
    
    // MARK: - UI Setup
        func configureUI() {
            // ✅ UPDATED: Prioritize parentSubject (The Folder Name)
            var displayName = "Quiz"
            
            if let subject = parentSubject, !subject.isEmpty {
                displayName = subject
            } else if let source = quizSourceName, !source.isEmpty {
                displayName = source
            } else if let topicName = currentTopic?.name {
                displayName = topicName
            }
            
            // Remove existing "Quiz" text if present to avoid "Calculus Quiz Quiz"
            let cleanName = displayName.replacingOccurrences(of: " Quiz", with: "")
            
            quizTitleLabel.text = "\(cleanName) Quiz"
            self.title = cleanName
            
            rulesTextView.text = generateRulesText()
        }
    
    func designButtons() {
        beginButton.layer.cornerRadius = 10
        beginButton.clipsToBounds = true
        
        saveAndCloseButton.layer.cornerRadius = 10
        saveAndCloseButton.clipsToBounds = true
    }
    
    func generateRulesText() -> String {
        return """
        1. This quiz is not marked and will not affect any official course grades or records. Use it as a self-assessment tool.
        
        2. For Multiple Choice questions, select the best single answer.
        
        3. Tap the single correct option to select your answer.
        
        4. Use the Next button at the bottom of the screen to move forward. You can use the Back button (if available) to review previous answers.
        
        5. Tap the Submit button on the final question to end the quiz and view your score.
        """
    }
    
    // MARK: - Actions
    
    @IBAction func beginQuizPressed(_ sender: Any) {
        performSegue(withIdentifier: "BeginQuizAction", sender: currentTopic)
    }
    
    @IBAction func saveQuizPressed(_ sender: Any) {
        guard let topic = currentTopic,
              let subject = parentSubject else {
            print("❌ Error: Missing topic or subject name")
            return
        }
        
        // Prepare topic copy
        let quizToSave = Topic(
            name: topic.name,
            lastAccessed: "Just now",
            materialType: "Quiz",
            parentSubjectName: subject, largeContentBody: topic.largeContentBody,
            notesContent: topic.notesContent,
            cheatsheetContent: topic.cheatsheetContent
        )
        
        // Save via DataManager
        DataManager.shared.addTopic(to: subject, topic: quizToSave)
        
        print("✅ Saved \(topic.name) to \(subject)")
        
        // Alert Logic
        showSaveAlert(folderName: subject)
    }
    
    // MARK: - Helper Alert
    func showSaveAlert(folderName: String) {
        let alert = UIAlertController(
            title: "Saved!",
            message: "Quiz has been successfully saved to '\(folderName)'.",
            preferredStyle: .alert
        )
        
        // ✅ MODIFIED: Navigate to Home Screen upon tapping OK
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Check if we are in a navigation stack
            if let nav = self.navigationController {
                // Pop to the root view controller (Home Screen)
                nav.popToRootViewController(animated: true)
            } else {
                // If presented modally, dismiss it
                self.dismiss(animated: true, completion: nil)
            }
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BeginQuizAction" {
            if let destinationVC = segue.destination as? QuizSessionViewController { // ✅ Ensure this matches your destination class
                
                // Pass data to the Quiz VC
                destinationVC.currentTopic = self.currentTopic
                destinationVC.parentSubject = self.parentSubject
                
                // Pass the same clean name to the next screen
                let nameToPass = self.parentSubject ?? self.quizSourceName ?? "Quiz"
                destinationVC.sourceName = nameToPass
                
                print("QuizStartVC: Forwarding \(currentTopic?.name ?? "nil")")
            }
        }
    }
}
