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
        
       
        title = selectedSourceName ?? quizTopic?.name ?? "Quiz"
        
       
        if let contentBody = quizTopic?.largeContentBody, !contentBody.isEmpty {
            
            self.allQuestions = unpackQuestions(from: contentBody)
            print(" Loaded \(allQuestions.count) dynamic questions from JSON")
        } else {
            // Fallback for your hardcoded PDF quizzes
            let sourceToLoad = self.selectedSourceName ?? "Taylor Series PDF"
            allQuestions = QuizManager.getQuestions(for: sourceToLoad)
            print(" Falling back to static QuizManager")
        }

        setupButtons()
        setupNavigationBarButtons()
        displayQuestion()
        startTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
   
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

            
            navigationItem.rightBarButtonItems = [newFlagItem, newHintItem]
        }
    }
  

    func displayQuestion() {
       
        guard currentQuestionIndex < allQuestions.count else {
            
            let finalResults = processQuizResults()
            
            
            performSegue(withIdentifier: "ShowQuizResults", sender: finalResults)
            
            return
        }

        
        let question = allQuestions[currentQuestionIndex]
        
       
        title = "Question \(currentQuestionIndex + 1)/\(allQuestions.count)"
        
        updateFlagButtonAppearance()
        
        questionLabel.text = question.questionText
        
       
        resetAnswerButtonAppearance()
        
        
        if let savedIndex = question.userAnswerIndex {
            let selectedButton = answerButtons[savedIndex]
            
            
            selectedButton.backgroundColor = UIColor.systemGray4
            selectedButton.layer.borderColor = UIColor.systemBlue.cgColor
            selectedButton.layer.borderWidth = 2.0
        }
        
        
        let isLastQuestion = (currentQuestionIndex == allQuestions.count - 1)
        
        
        previousButton.isHidden = (currentQuestionIndex == 0)

        
        nextButton.isHidden = false
        
        if isLastQuestion {
            
            nextButton.setTitle("Finish", for: .normal)
            nextButton.removeTarget(nil, action: nil, for: .allEvents)
            nextButton.addTarget(self, action: #selector(finishQuizTapped), for: .touchUpInside)
        } else {
            
            nextButton.setTitle("Next", for: .normal)
            nextButton.removeTarget(nil, action: nil, for: .allEvents)
            nextButton.addTarget(self, action: #selector(goToNextQuestion), for: .touchUpInside)
        }
        
       
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
            button.isEnabled = true
        }
    }
    func startTimer() {
       
        countdownTimer?.invalidate()
        
        
        if totalTime > 0 {
            timeRemaining = totalTime
            timerLabel.isHidden = false
            updateTimerLabel()
            
            
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
        
        currentQuestionIndex += 1
        displayQuestion()
    }

    @objc func finishQuizTapped() {
       
        currentQuestionIndex += 1
        displayQuestion()
    }
   

    @objc func backButtonTapped() {
        let alert = UIAlertController(title: "Quit Quiz", message: "Exit the quiz? Your current progress will be saved for later.", preferredStyle: .alert)
        
       
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            
            self?.navigationController?.popViewController(animated: true)
        })
        
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        
        present(alert, animated: true)
    }
    

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
        
        allQuestions[currentQuestionIndex].isFlagged.toggle()
        
       
        updateFlagButtonAppearance()
        
        print("Question \(currentQuestionIndex + 1) flagged status: \(allQuestions[currentQuestionIndex].isFlagged)")
    }
    

    

    func updateFlagButtonAppearance() {
        guard currentQuestionIndex < allQuestions.count,
              let flagButton = self.flagBarItem else {
            return
        }
        
        let currentQuestion = allQuestions[currentQuestionIndex]
        
        
        let systemName = currentQuestion.isFlagged ? "flag.fill" : "flag"
        flagButton.image = UIImage(systemName: systemName)
        
        
        flagButton.tintColor = currentQuestion.isFlagged ? .systemRed : .systemGray
    }
    @objc func handleTimerTick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            updateTimerLabel()
        } else {
            
            countdownTimer?.invalidate()
            
        }
    }
    func updateTimerLabel() {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        timerLabel.text = String(format: "%02i:%02i", minutes, seconds)
        
       
        if timeRemaining <= 60 {
            timerLabel.textColor = .systemRed
        } else {
            timerLabel.textColor = .darkGray
        }
    }
    
    func processQuizResults() -> FinalQuizResult {
        var finalScore = 0
        var detailResults: [QuestionResultDetail] = []
        
       

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

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ShowQuizResults" {
          
            if let resultsVC = segue.destination as? ResultsViewController,
               let results = sender as? FinalQuizResult {
                
               
                resultsVC.finalResult = results
            }
        }
    }
    private func unpackQuestions(from content: String) -> [QuizQuestion] {
        let lines = content.components(separatedBy: "\n")
        var loadedQuestions: [QuizQuestion] = []
        
        for line in lines where !line.isEmpty {
            let parts = line.components(separatedBy: "|")
            
            // Ensure we have at least Question + 4 Answers
            if parts.count >= 5 {
                let questionText = parts[0]
                let ans1 = parts[1]
                let ans2 = parts[2]
                let ans3 = parts[3]
                let ans4 = parts[4]
                let answers = [ans1, ans2, ans3, ans4]
                
                // Handle Correct Index (Part 6) - Fallback to 0 if missing
                let correctIndex = parts.count > 5 ? (Int(parts[5]) ?? 0) : 0
                
                // Handle Hint (Part 7) - Fallback to generic hint if missing
                let hintText = parts.count > 6 ? parts[6] : "Focus on the core concepts."
                
                let question = QuizQuestion(
                    questionText: questionText,
                    answers: answers,
                    correctAnswerIndex: correctIndex,
                    userAnswerIndex: nil,
                    isFlagged: false,
                    hint: hintText
                )
                loadedQuestions.append(question)
            }
        }
        print("✅ Successfully unpacked \(loadedQuestions.count) questions")
        return loadedQuestions
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
