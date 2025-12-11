//
//  QuizViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 11/12/25.
//

import UIKit

class QuizViewController: UIViewController,UINavigationControllerDelegate {
    var quizTopic: Topic?
    var parentSubjectName: String?
        
    // MARK: - Outlets (Connect these in Storyboard)
    @IBOutlet weak var questionLabel: UILabel!
    // Connect ALL 4 answer buttons to this single outlet collection
    @IBOutlet var answerButtons: [UIButton]!
    
    @IBOutlet var previousButton: UIButton!
    
    @IBOutlet var nextButton: UIButton!
    

    var allQuestions = QuizManager.quiz
    var currentQuestionIndex = 0
    var score = 0

    // QuizViewController.swift

    // QuizViewController.swift (In viewDidLoad)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = quizTopic?.name ?? "Quiz"
        
        // 1. Setup the custom back button (Correct)
        navigationItem.hidesBackButton = true
        let quitButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = quitButton
        
        setupButtons()
        setupNavigationBarButtons()
        displayQuestion()
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
//    @IBAction func nextButtonTapped(_ sender: Any) {
//        // Targets are assigned dynamically in displayQuestion()
//    }
//    
    @IBAction func previousButtonTapped(_ sender: Any) {
        goToPreviousQuestion()
    }
    
    func setupButtons() {
        for button in answerButtons {
            // Disable UIButtonConfiguration so classic properties (like contentEdgeInsets) apply
            button.configuration = nil

            // Visual Styling for Sleek Card Look
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
    // QuizViewController.swift (Add this function)

    func setupNavigationBarButtons() {
        // Check if the buttons are already installed
        if navigationItem.rightBarButtonItems == nil || navigationItem.rightBarButtonItems?.isEmpty == true {
            
            let hintItem = UIBarButtonItem(image: UIImage(systemName: "lightbulb"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(hintButtonTapped))
            
            let flagItem = UIBarButtonItem(image: UIImage(systemName: "flag"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(flagButtonTapped))
            
            // Install the buttons
            navigationItem.rightBarButtonItems = [flagItem, hintItem]
        }
    }
  

    func displayQuestion() {
        // 1. --- Check for Quiz Completion ---
        guard currentQuestionIndex < allQuestions.count else {
            // END OF QUIZ: Display score.
            title = "Finished!"
            questionLabel.text = "Quiz Complete! Your Score: \(score)/\(allQuestions.count)"
            
            // Hide all buttons and remove navigation bar items
            answerButtons.forEach { $0.isHidden = true }
            previousButton.isHidden = true
            nextButton.isHidden = true
            
            navigationItem.rightBarButtonItems = [] // Clear Hint/Flag from score screen
            navigationItem.hidesBackButton = false
            return
        }

        // Question is active:
        let question = allQuestions[currentQuestionIndex]
        
        // Update navigation bar title
        title = "Question \(currentQuestionIndex + 1)/\(allQuestions.count)"
        
        // ❌ REMOVED: The logic to install Hint/Flag buttons is GONE from here.
        //             It should be called only once from viewDidLoad or setupNavigationBarButtons().
        
        // ⭐️ KEEP: Update the flag icon state ⭐️
        updateFlagButtonAppearance() // This ensures the icon reflects the current question's state
        
        questionLabel.text = question.questionText
        
        // Reset ALL buttons to clean, clear state first
        resetAnswerButtonAppearance()
        
        // ⭐️ RESTORE PREVIOUS ANSWER STATE (Neutral Highlight) ⭐️
        if let savedIndex = question.userAnswerIndex {
            let selectedButton = answerButtons[savedIndex]
            
            // Apply a NEUTRAL highlight
            selectedButton.backgroundColor = UIColor.systemGray4
            selectedButton.layer.borderColor = UIColor.systemBlue.cgColor
            selectedButton.layer.borderWidth = 2.0
        }
        
        // --- Dynamic Bottom Button Logic ---
        let isLastQuestion = (currentQuestionIndex == allQuestions.count - 1)
        
        // Previous Button: Only visible AFTER the first question (Index 0)
        previousButton.isHidden = (currentQuestionIndex == 0)

        // Next/Finish Button Logic:
        nextButton.isHidden = false
        
        if isLastQuestion {
            // LAST QUESTION: Set button to FINISH and link to finish action
            nextButton.setTitle("Finish", for: .normal)
            nextButton.removeTarget(nil, action: nil, for: .allEvents)
            nextButton.addTarget(self, action: #selector(finishQuizTapped), for: .touchUpInside)
        } else {
            // ALL OTHER QUESTIONS: Set button to NEXT and link to next action
            nextButton.setTitle("Next", for: .normal)
            nextButton.removeTarget(nil, action: nil, for: .allEvents)
            nextButton.addTarget(self, action: #selector(goToNextQuestion), for: .touchUpInside)
        }
        
        // Populate text with A., B., C., D. prefixes
        let prefixes = ["A.", "B.", "C.", "D."]
        for (index, button) in answerButtons.enumerated() {
            let fullAnswerText = "\(prefixes[index]) \(question.answers[index])"
            button.setTitle(fullAnswerText, for: .normal)
            button.isHidden = false
        }
    }
    func resetAnswerButtonAppearance() {
        for button in answerButtons {
            button.backgroundColor = .clear
            button.layer.borderColor = UIColor.systemGray3.cgColor
            button.layer.borderWidth = 1.0
            button.isEnabled = true // Temporarily re-enable everything
        }
    }
    
    @IBAction func answerTapped(_ sender: UIButton) {
        // ⭐️ 1. Reset all buttons visually and re-enable them (Crucial for clearing old highlight) ⭐️
            // The resetAnswerButtonAppearance() ensures that if a highlight was showing, it's gone.
            resetAnswerButtonAppearance()
            
            // Determine which button was tapped
            guard let tappedIndex = answerButtons.firstIndex(of: sender) else { return }

            // 2. SAVE THE NEW USER'S ANSWER STATE
            allQuestions[currentQuestionIndex].userAnswerIndex = tappedIndex

            // 3. Apply the visual confirmation highlight to the *newly tapped* button
            sender.backgroundColor = UIColor.systemGray4 // Neutral color for selection
            sender.layer.borderColor = UIColor.systemBlue.cgColor
            sender.layer.borderWidth = 2.0

            // 4. Unlock the Navigation Buttons (They are ready to go)
            self.previousButton.isEnabled = true
            self.nextButton.isEnabled = true
    }
    
    // MARK: - Navigation actions

    @objc func goToPreviousQuestion() {
        // Ensure we don't go past the first question
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            displayQuestion()
        }
    }
    
    // QuizViewController.swift

    // ⭐️ ADD @objc HERE ⭐️
    @objc func exitQuizTapped() {
        // 1. Give the user a warning
        let alert = UIAlertController(title: "End Quiz?", message: "Are you sure you want to exit? Your current progress will be lost.", preferredStyle: .alert)
        
        // 2. Action to confirm and exit
        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { [weak self] _ in
            // Navigates back to the previous screen (InstructionViewController)
            self?.navigationController?.popViewController(animated: true)
        })
        
        // 3. Action to cancel
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }

    @objc func goToNextQuestion() {
        // This action is linked to the "Next" button.
        currentQuestionIndex += 1
        displayQuestion()
    }

    @objc func finishQuizTapped() {
        // This action is linked to the "Next" button when its title is "Finish".
        currentQuestionIndex += 1 // Triggers the end-of-quiz logic
        displayQuestion()
    }
    // QuizViewController.swift

    @objc func backButtonTapped() {
        let alert = UIAlertController(title: "Quit Quiz", message: "Exit the quiz? Your current progress will be saved for later.", preferredStyle: .alert)
        
        // Action 1: YES (Quit)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            // Pop back to the previous view controller (InstructionViewController)
            self?.navigationController?.popViewController(animated: true)
        })
        
        // Action 2: NO (Continue)
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        
        present(alert, animated: true)
    }
    // QuizViewController.swift

    @objc func hintButtonTapped() {
        // Logic to show a simple alert hint
        print("Hint button tapped for question \(currentQuestionIndex + 1)")
        
        let alert = UIAlertController(title: "Hint Available", message: "Consider the context of Data Structures. What type of storage best fits this question?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }

    @objc func flagButtonTapped() {
        // 1. Toggle the flag status in the data model
        allQuestions[currentQuestionIndex].isFlagged.toggle()
        
        // 2. Update the button's appearance immediately
        updateFlagButtonAppearance()
        
        print("Question \(currentQuestionIndex + 1) flagged status: \(allQuestions[currentQuestionIndex].isFlagged)")
    }

    func updateFlagButtonAppearance() {
        guard currentQuestionIndex < allQuestions.count else { return }
        let currentQuestion = allQuestions[currentQuestionIndex]
        
        // Find the flag button item (assuming it's the second item in the right bar button array, or the last one)
        if let flagButton = navigationItem.rightBarButtonItems?.first(where: { $0.action == #selector(flagButtonTapped) }) {
            
            let systemName = currentQuestion.isFlagged ? "flag.fill" : "flag"
            flagButton.image = UIImage(systemName: systemName)
            
            // Optional: Change tint color when flagged
            flagButton.tintColor = currentQuestion.isFlagged ? .systemRed : .systemGray
        }
    }
    // QuizViewController.swift

    
   
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}
