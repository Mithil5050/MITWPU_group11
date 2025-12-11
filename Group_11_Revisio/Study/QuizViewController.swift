//
//  QuizViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 11/12/25.
//

import UIKit

class QuizViewController: UIViewController {
    var quizTopic: Topic?
    var parentSubjectName: String?
        
        // MARK: - Outlets (Connect these in Storyboard)
        @IBOutlet weak var questionLabel: UILabel!
        // Connect ALL 4 answer buttons to this single outlet collection
        @IBOutlet var answerButtons: [UIButton]!
       let allQuestions = QuizManager.quiz // Loads static quiz data
        var currentQuestionIndex = 0
        var score = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = quizTopic?.name ?? "Quiz"
                
                // Hide the system back button while the quiz is active
                navigationItem.hidesBackButton = true
                
                setupButtons()
                displayQuestion()

        // Do any additional setup after loading the view.
    }
    func setupButtons() {
            for button in answerButtons {
                // Disable UIButtonConfiguration so classic properties (like contentEdgeInsets) apply
                button.configuration = nil

                // ⭐️ Visual Styling for Sleek Card Look (Matching Mockup) ⭐️
                button.layer.cornerRadius = 16
                button.clipsToBounds = true
                
                // Subtle Gray Border for the unselected look
                button.layer.borderWidth = 1.0
                button.layer.borderColor = UIColor.systemGray3.cgColor
                
                // Text alignment, padding, and font style
                button.titleLabel?.lineBreakMode = .byWordWrapping
                button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
                
                // Initial state: Clear background (relying on the border for visibility)
                button.backgroundColor = .clear
                
                // Ensure content is left-aligned in the button title
                button.contentHorizontalAlignment = .left
            }
        }

    // QuizViewController.swift

    func displayQuestion() {
        // Update navigation bar title to show question number
        title = "Question \(currentQuestionIndex + 1)/\(allQuestions.count)"

        guard currentQuestionIndex < allQuestions.count else {
            // End of Quiz: Show score, etc.
            title = "Finished!"
            questionLabel.text = "Quiz Complete! Your Score: \(score)/\(allQuestions.count)"
            answerButtons.forEach { $0.isHidden = true }
            navigationItem.hidesBackButton = false
            return
        }
        
        let question = allQuestions[currentQuestionIndex]
        questionLabel.text = question.questionText
        
        // Define the prefixes: A, B, C, D
        let prefixes = ["A.", "B.", "C.", "D."]

        // Reset buttons for the new question
        for (index, button) in answerButtons.enumerated() {
            
            // ⭐️ CRITICAL CHANGE HERE ⭐️
            // Combine the prefix (A., B., C., D.) with the answer text
            let fullAnswerText = "\(prefixes[index]) \(question.answers[index])"
            
            button.setTitle(fullAnswerText, for: .normal)
            
            // Reset to initial sleek appearance
            button.backgroundColor = .clear
            button.layer.borderColor = UIColor.systemGray3.cgColor
            button.isEnabled = true
            button.isHidden = false
        }
    }
    @IBAction func answerTapped(_ sender: UIButton) {
            // Disable all buttons immediately to prevent multiple taps
            answerButtons.forEach { $0.isEnabled = false }
            
            let question = allQuestions[currentQuestionIndex]
            let correctIndex = question.correctAnswerIndex
            
            // Determine which button was tapped
            guard let tappedIndex = answerButtons.firstIndex(of: sender) else { return }

            // --- Apply temporary Selection Highlight (Purple Ring) ---
            let selectionColor = UIColor.systemPurple
            sender.layer.borderColor = selectionColor.cgColor
            sender.layer.borderWidth = 2.0 // Thicker border for visual feedback
            
            // Wait a brief moment before applying final Red/Green feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }

                // Reset border thickness and apply final colors
                sender.layer.borderWidth = 1.0
                
                if tappedIndex == correctIndex {
                    // Correct Answer: Green
                    sender.backgroundColor = .systemGreen
                    sender.layer.borderColor = UIColor.systemGreen.cgColor
                    self.score += 1
                } else {
                    // Wrong Answer: Red
                    sender.backgroundColor = .systemRed
                    sender.layer.borderColor = UIColor.systemRed.cgColor
                    
                    // Highlight correct answer in Green
                    self.answerButtons[correctIndex].backgroundColor = .systemGreen
                    self.answerButtons[correctIndex].layer.borderColor = UIColor.systemGreen.cgColor
                }

                // Move to next question after additional delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    self.currentQuestionIndex += 1
                    self.displayQuestion()
                }
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

}
