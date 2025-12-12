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
    
    @IBOutlet var titleLabel: UILabel!
    
    
    @IBOutlet var instructionsTextView: UITextView!
    
    
    @IBOutlet var attemptQuizButton: UIButton!
    
    @IBOutlet var saveExitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = false
                
                
        setupLabels()
                
                
        styleButtons()
        
        //getInstructionsText()

        // Do any additional setup after loading the view.
    }
    func setupLabels() {
            // Set the main title (e.g., "Hadoop Fundamentals Quiz")
            if let topicName = quizTopic?.name {
                 titleLabel.text = "\(topicName) Quiz"
            } else {
                 titleLabel.text = "Quiz Instructions"
            }
            
            // Load the detailed instructions text
            instructionsTextView.text = getInstructionsText()
            
            // Optional: If you want to customize the metadata label ("16 Questions | 20 minutes")
            // You would need an outlet for that label and set its text here as well.
        }
        
        func styleButtons() {
            // Apply rounded corners (You might have done this in the Storyboard, but enforcing it here is safe)
            attemptQuizButton.layer.cornerRadius = 10
            attemptQuizButton.clipsToBounds = true
            
            saveExitButton.layer.cornerRadius = 10
            saveExitButton.clipsToBounds = true
        }

        // Returns the static rules for the quiz
        func getInstructionsText() -> String {
            return """
            1. This quiz is not marked and will not affect any official course grades or records. Use it as a self-assessment tool.
            
            2. For Multiple Choice questions, select the best single answer.
            
            3. Tap the single correct option to select your answer.
            
            4. Use the Next button at the bottom of the screen to move forward. You can use the Back button (if available) to review previous answers.
            
            5. Tap the Submit button on the final question to end the quiz and view your score.
            """
        }
    
    @IBAction func attemptQuizTapped(_ sender: Any) {
        //performSegue(withIdentifier: "StartQuiz", sender: quizTopic)
    }
    
    @IBAction func saveAndExitTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            
            // Check for the correct segue identifier first
            if segue.identifier == "StartQuiz" {
                
                // Use a single 'if let' block to safely unwrap BOTH the destination VC and the sender data
                if let quizVC = segue.destination as? QuizViewController,
                   let topic = sender as? Topic {
                    
                    // These lines are now INSIDE the 'if let' block, so quizVC is in scope
                    quizVC.quizTopic = topic
                    quizVC.parentSubjectName = parentSubjectName // Assuming this property is defined in the class
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
