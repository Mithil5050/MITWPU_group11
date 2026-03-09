//
//  InstructionViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 11/12/25.
//

import UIKit

class InstructionViewController: UIViewController {
    var quizTopic: Topic?
    var parentSubjectName: String?
    var sourceNameForQuiz: String?
    var quizTimeLimit: Int = 15
    var quizQuestionCount: Int = 10
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel?
    @IBOutlet var instructionsTextView: UITextView!
    @IBOutlet var attemptQuizButton: UIButton!
    @IBOutlet var saveExitButton: UIButton!
    
    private var programmaticMetadataLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = false
        setupLabels()
        setupProgrammaticMetadataLabel()
        styleButtons()
    }

    func setupLabels() {
        let displayName = sourceNameForQuiz ?? quizTopic?.name ?? "Quiz"
        titleLabel.text = "\(displayName) Quiz"
        self.title = displayName
        
        instructionsTextView.text = getInstructionsText()
    }
    
    func setupProgrammaticMetadataLabel() {
        let questionCount = quizQuestionCount > 0 ? quizQuestionCount : (quizTopic?.quizQuestions?.count ?? 0)
        
        let metaLabel = UILabel()
        metaLabel.text = "\(questionCount) Questions | \(quizTimeLimit) Minutes"
        metaLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        metaLabel.textColor = .secondaryLabel
        metaLabel.textAlignment = .left
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.superview?.addSubview(metaLabel)
        
        NSLayoutConstraint.activate([
            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
        
        self.programmaticMetadataLabel = metaLabel
    }

    func styleButtons() {
        attemptQuizButton.layer.cornerRadius = 10
        attemptQuizButton.clipsToBounds = true
        saveExitButton.layer.cornerRadius = 10
        saveExitButton.clipsToBounds = true
    }

    func getInstructionsText() -> String {
        return """
        1. This quiz is not marked and will not affect any official course grades or records. Use it as a self-assessment tool.
        
        2. Time Limit: You have \(quizTimeLimit) minutes to complete this session.
        
        3. For Multiple Choice questions, select the best single answer.
        
        4. Use the Next button at the bottom of the screen to move forward. You can use the Back button (if available) to review previous answers.
        
        5. Tap the Submit button on the final question to end the quiz and view your score.
        """
    }
    
    @IBAction func attemptQuizTapped(_ sender: Any) {
        performSegue(withIdentifier: "StartQuiz", sender: quizTopic)
    }
    
    @IBAction func saveAndExitTapped(_ sender: Any) {
        guard let topic = quizTopic, let subject = parentSubjectName else {
            print(" Error: Missing topic or subject name")
            return
        }
            
        let alert = UIAlertController(
            title: "Saved!",
            message: "Quiz has been successfully saved to '\(subject)'.",
            preferredStyle: .alert
        )
            
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            let quizToSave = Topic(
                name: topic.name,
                lastAccessed: "Just now",
                materialType: "Quiz",
                parentSubjectName: subject,
                quizQuestions: topic.quizQuestions,
                largeContentBody: topic.largeContentBody,
                notesContent: topic.notesContent,
                cheatsheetContent: topic.cheatsheetContent
            )
                
            DataManager.shared.addTopic(to: subject, topic: quizToSave)
                
            if let nav = self?.navigationController {
                for vc in nav.viewControllers {
                    if vc is SubjectViewController {
                        nav.popToViewController(vc, animated: true)
                        return
                    }
                }
                nav.popViewController(animated: true)
            } else {
                self?.dismiss(animated: true)
            }
        })
            
        present(alert, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartQuiz" {
            if let quizVC = segue.destination as? QuizViewController {
                quizVC.quizTopic = self.quizTopic
                quizVC.parentSubjectName = self.parentSubjectName
                let nameToPass = self.sourceNameForQuiz ?? self.quizTopic?.name ?? "Quiz"
                quizVC.selectedSourceName = nameToPass
                quizVC.timeLimitInMinutes = self.quizTimeLimit
            }
        }
    }
}
