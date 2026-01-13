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
    
    @IBOutlet var titleLabel: UILabel!
    
    
    @IBOutlet var instructionsTextView: UITextView!
    
    
    @IBOutlet var attemptQuizButton: UIButton!
    
    @IBOutlet var saveExitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = false
                
                
        setupLabels()
                
                
        styleButtons()
}
    

    func setupLabels() {
        
        let displayName = sourceNameForQuiz ?? quizTopic?.name ?? "Quiz"
        
        
        titleLabel.text = "\(displayName) Quiz"
        self.title = displayName
        
        instructionsTextView.text = getInstructionsText()
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
            
            2. For Multiple Choice questions, select the best single answer.
            
            3. Tap the single correct option to select your answer.
            
            4. Use the Next button at the bottom of the screen to move forward. You can use the Back button (if available) to review previous answers.
            
            5. Tap the Submit button on the final question to end the quiz and view your score.
            """
        }
    
    @IBAction func attemptQuizTapped(_ sender: Any) {
        performSegue(withIdentifier: "StartQuiz", sender: quizTopic)
    }
    
    @IBAction func saveAndExitTapped(_ sender: Any) {
        guard let topic = quizTopic,
                  let subject = parentSubjectName else {
                print("❌ Error: Missing topic or subject name")
                return
            }
            
            // 2. Prepare the topic specifically as a Quiz type
            // We use the existing largeContentBody which contains the packed questions
            let quizToSave = Topic(
                name: topic.name,
                lastAccessed: "Just now",
                materialType: "Quiz",
                largeContentBody: topic.largeContentBody,
                parentSubjectName: subject,
                notesContent: topic.notesContent,
                cheatsheetContent: topic.cheatsheetContent
            )
            
            // 3. Save it to the DataManager
            DataManager.shared.addTopic(to: subject, topic: quizToSave)
            
            // 4. Visual Feedback (Optional but recommended)
            print("✅ Saved \(topic.name) to \(subject)")
            
            // 5. Dismiss or Pop back to the folder
            if let nav = self.navigationController {
                nav.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
    }
   

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartQuiz" {
            if let quizVC = segue.destination as? QuizViewController {
                
                
                quizVC.quizTopic = self.quizTopic
                
                quizVC.parentSubjectName = self.parentSubjectName
              
                let nameToPass = self.sourceNameForQuiz ?? self.quizTopic?.name ?? "Quiz"
                quizVC.selectedSourceName = nameToPass
                
                print("InstructionVC: Forwarding \(quizTopic?.name ?? "nil") and Subject: \(parentSubjectName ?? "nil")")
            }
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


