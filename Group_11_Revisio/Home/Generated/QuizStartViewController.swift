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
            // Prioritize parentSubject (The Folder Name)
            var displayName = "Quiz"
            
            if let subject = parentSubject, !subject.isEmpty {
                displayName = subject
            } else if let source = quizSourceName, !source.isEmpty {
                displayName = source
            } else if let topicName = currentTopic?.name {
                displayName = topicName
            }
            
            // Clean up name
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
        
        4. Use the Next button at the bottom of the screen to move forward.
        
        5. Tap the Submit button on the final question to end the quiz.
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
            parentSubjectName: subject,
            largeContentBody: topic.largeContentBody,
            notesContent: topic.notesContent,
            cheatsheetContent: topic.cheatsheetContent
        )
        
        // Save via DataManager
        DataManager.shared.addTopic(to: subject, topic: quizToSave)
        
        print("✅ Saved \(topic.name) to \(subject)")
        showSaveAlert(folderName: subject)
    }
    
    func showSaveAlert(folderName: String) {
        let alert = UIAlertController(
            title: "Saved!",
            message: "Quiz has been successfully saved to '\(folderName)'.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if let nav = self.navigationController {
                nav.popToRootViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }

    // MARK: - Navigation (✅ FIXED: Handles BOTH View Controllers)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BeginQuizAction" {
            
            let nameToPass = self.parentSubject ?? self.quizSourceName ?? "Quiz"
            
            // 1. Try casting to the NEW QuizViewController
            if let newQuizVC = segue.destination as? QuizViewController {
                print("🚀 Launching QuizViewController")
                newQuizVC.quizTopic = self.currentTopic
                newQuizVC.parentSubjectName = self.parentSubject
                newQuizVC.selectedSourceName = nameToPass
                return
            }
            
            // 2. Try casting to the OLD QuizSessionViewController (Fallback)
            if let oldQuizVC = segue.destination as? QuizSessionViewController {
                print("🚀 Launching QuizSessionViewController")
                oldQuizVC.currentTopic = self.currentTopic
                oldQuizVC.parentSubject = self.parentSubject
                oldQuizVC.sourceName = nameToPass
                return
            }
            
            print("⚠️ CRITICAL ERROR: Segue destination matches neither QuizViewController nor QuizSessionViewController.")
        }
    }
}
