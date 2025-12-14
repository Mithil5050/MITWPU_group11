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
    
    @IBOutlet var answerButtons: [UIButton]!
    
    @IBOutlet var previousButton: UIButton!
    
    @IBOutlet var nextButton: UIButton!
    
    
    @IBOutlet var timerLabel: UILabel!
    
    var allQuestions : [QuizQuestion] = []
    var selectedSourceName:String?
    var currentQuestionIndex = 0
    var score = 0
    var hintBarItem: UIBarButtonItem?
    var flagBarItem: UIBarButtonItem?
    var countdownTimer: Timer?
    var totalTime = 300
    var timeRemaining = 0

    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ⭐️ CRITICAL FIX: Load questions based on selectedSourceName ⭐️
        // Use the selected name, or fall back to a safe default for stability (e.g., "Taylor Series PDF").
        let sourceToLoad = self.selectedSourceName ?? "Taylor Series PDF"
        
        // 1. Load the actual quiz data
        allQuestions = QuizManager.getQuestions(for: sourceToLoad)
        
        // 2. Set the title
        title = sourceToLoad // Set the title to the loaded source name
        
        // 3. Setup the custom back button (Remains Correct)
        navigationItem.hidesBackButton = true
        let quitButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = quitButton
        
        // 4. Setup UI elements
        setupButtons()
        setupNavigationBarButtons() // Installs Hint/Flag buttons
        
        // 5. Display the first question and start the timer
        displayQuestion()
        
        // ⭐️ FIX: Start the timer after all data is loaded ⭐️
        startTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    // SourceSelectionViewController.swift (This is the class *before* QuizViewController)

    // SourceSelectionViewController.swift (The view controller BEFORE QuizViewController)

   
    
//    @IBAction func nextButtonTapped(_ sender: Any) {
//        // Targets are assigned dynamically in displayQuestion()
//    }
//    
    @IBAction func previousButtonTapped(_ sender: Any) {
        goToPreviousQuestion()
    }
    
    func setupButtons() {
        for button in answerButtons {
           
            button.configuration = nil

            
            button.layer.cornerRadius = 16
            button.clipsToBounds = true
            
            
            button.layer.borderWidth = 1.0
            button.layer.borderColor = UIColor.systemGray3.cgColor
            
            
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
            
           
            button.backgroundColor = .clear
            
            
            button.contentHorizontalAlignment = .left
        }
    }
    // QuizViewController.swift (Add this function)

    func setupNavigationBarButtons() {
        // Check if the buttons are already installed (check our new properties)
        if self.flagBarItem == nil {
            
            // 1. Create the items
            let newHintItem = UIBarButtonItem(image: UIImage(systemName: "lightbulb"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(hintButtonTapped))
            
            let newFlagItem = UIBarButtonItem(image: UIImage(systemName: "flag"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(flagButtonTapped))
            
            
            self.hintBarItem = newHintItem
            self.flagBarItem = newFlagItem

            // 2. Install the buttons using the stored properties
            navigationItem.rightBarButtonItems = [newFlagItem, newHintItem]
        }
    }
  

    func displayQuestion() {
        // 1. --- Check for Quiz Completion ---
        guard currentQuestionIndex < allQuestions.count else {
            // QUIZ COMPLETE: Process results and trigger the segue

            // Process the final results (requires the processQuizResults function)
            let finalResults = processQuizResults()
            
            // Perform the segue to the ResultsViewController (Identifier: "ShowQuizResults")
            performSegue(withIdentifier: "ShowQuizResults", sender: finalResults)
            
            return // Stop execution; navigation takes over
        }

        // Question is active:
        let question = allQuestions[currentQuestionIndex]
        
        // Update navigation bar title
        title = "Question \(currentQuestionIndex + 1)/\(allQuestions.count)"
        
        updateFlagButtonAppearance()
        
        questionLabel.text = question.questionText
        
        // Reset ALL buttons to clean, clear state first
        resetAnswerButtonAppearance()
        
        
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
    func startTimer() {
        // Stop any existing timer first
        countdownTimer?.invalidate()
        
        // Check if the user set a limit (e.g., from a settings screen, let's assume 300s = 5 min)
        if totalTime > 0 {
            timeRemaining = totalTime
            timerLabel.isHidden = false
            updateTimerLabel()
            
            // Create a new timer that fires every 1 second
            countdownTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                  target: self,
                                                  selector: #selector(handleTimerTick),
                                                  userInfo: nil,
                                                  repeats: true)
        } else {
            timerLabel.isHidden = true
        }
    }
    
    @IBAction func answerTapped(_ sender: UIButton) {
       
            resetAnswerButtonAppearance()
            
            
            guard let tappedIndex = answerButtons.firstIndex(of: sender) else { return }

           
            allQuestions[currentQuestionIndex].userAnswerIndex = tappedIndex

            
            sender.backgroundColor = UIColor.systemGray4 // Neutral color for selection
            sender.layer.borderColor = UIColor.systemBlue.cgColor
            sender.layer.borderWidth = 2.0

            
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
    
  

   
    @objc func exitQuizTapped() {
        
        let alert = UIAlertController(title: "End Quiz?", message: "Are you sure you want to exit? Your current progress will be lost.", preferredStyle: .alert)
        
       
        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { [weak self] _ in
            
            self?.navigationController?.popViewController(animated: true)
        })
        
       
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

    // QuizViewController.swift

    @objc func hintButtonTapped() {
        let currentQuestion = allQuestions[currentQuestionIndex]
        
        let alert = UIAlertController(
            title: "Hint (\(currentQuestionIndex + 1)/\(allQuestions.count))",
            message: currentQuestion.hint, 
            preferredStyle: .alert
        )
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
    

    // QuizViewController.swift

    func updateFlagButtonAppearance() {
        guard currentQuestionIndex < allQuestions.count,
              let flagButton = self.flagBarItem else {
            return
        }
        
        let currentQuestion = allQuestions[currentQuestionIndex]
        
        // Direct access to the stored property is fast and reliable
        let systemName = currentQuestion.isFlagged ? "flag.fill" : "flag"
        flagButton.image = UIImage(systemName: systemName)
        
        // Optional: Change tint color when flagged
        flagButton.tintColor = currentQuestion.isFlagged ? .systemRed : .systemGray
    }
    @objc func handleTimerTick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            updateTimerLabel()
        } else {
            // Time is up!
            countdownTimer?.invalidate()
            // Optional: Automatically trigger the end of the quiz here
            // self.finishQuizTapped()
        }
    }
    func updateTimerLabel() {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        timerLabel.text = String(format: "%02i:%02i", minutes, seconds)
        
        // Optional: Change color if time is low
        if timeRemaining <= 60 {
            timerLabel.textColor = .systemRed
        } else {
            timerLabel.textColor = .darkGray
        }
    }
    // Add this logic method to process and package the final results
    func processQuizResults() -> FinalQuizResult {
        var finalScore = 0
        var detailResults: [QuestionResultDetail] = []
        
        // NOTE: Requires QuestionResultDetail and FinalQuizResult structs to be visible (e.g., in Models.swift)

        for question in allQuestions {
            let wasCorrect = (question.userAnswerIndex == question.correctAnswerIndex)
            if wasCorrect {
                finalScore += 1
            }
            
            let selectedAnswerText: String? = question.userAnswerIndex.map { question.answers[$0] }
            let correctAnswerText = question.answers[question.correctAnswerIndex]
            
            let detail = QuestionResultDetail(
                questionText: question.questionText,
                wasCorrect: wasCorrect,
                selectedAnswer: selectedAnswerText,
                correctAnswerFullText: correctAnswerText ,
                isFlagged: question.isFlagged
            )
            detailResults.append(detail)
        }
        
        let timeElapsed = TimeInterval(totalTime - timeRemaining)
        countdownTimer?.invalidate()
        
        let finalResult = FinalQuizResult(
            finalScore: finalScore,
            totalQuestions: allQuestions.count,
            timeElapsed: timeElapsed,
            sourceName: self.selectedSourceName ?? "Quiz",
            details: detailResults
        )
        
        return finalResult
    }

    // Add this prepare method to handle the data transfer during the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Check for the specific segue identifier (confirmed as ShowQuizResults)
        if segue.identifier == "ShowQuizResults" {
            // Destination is the ResultsViewController
            if let resultsVC = segue.destination as? ResultsViewController,
               let results = sender as? FinalQuizResult {
                
                // Pass the FinalQuizResult data
                resultsVC.finalResult = results
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
