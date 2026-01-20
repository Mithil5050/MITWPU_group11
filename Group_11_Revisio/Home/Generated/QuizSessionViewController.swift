//
//  QuizSessionViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 18/01/26.
//

import UIKit

class QuizSessionViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var quizQuestionLabel: UILabel!
    
    // ✅ FIX: Removed 'weak' keyword here
    @IBOutlet var optionButtons: [UIButton]!
    
    @IBOutlet weak var backQButton: UIButton!
    @IBOutlet weak var forwardQButton: UIButton!
    @IBOutlet weak var countdownLabel: UILabel!
    
    // MARK: - Properties
    var currentTopic: Topic?
    var parentSubject: String?
    
    var sessionQuestions: [QuizQuestion] = []
    // Separate array for explanations
    var explanations: [String] = []
    
    var questionIndex = 0
    var sourceName: String? = "CS Quiz"
    
    var hintItem: UIBarButtonItem?
    var flagItem: UIBarButtonItem?
    
    var sessionTimer: Timer?
    var totalSessionTime = 300
    var secondsRemaining = 0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = sourceName
        loadDummyData()
        styleOptionButtons()
        configureNavBarItems()
        renderQuestion()
        initiateTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionTimer?.invalidate()
    }
    
    // MARK: - Dummy Data with Explanations
    func loadDummyData() {
        // 1. Questions
        sessionQuestions = [
            QuizQuestion(
                questionText: "Which data structure follows the LIFO principle?",
                answers: ["Queue", "Stack", "Linked List", "Tree"],
                correctAnswerIndex: 1, userAnswerIndex: nil, isFlagged: false,
                hint: "Think about a stack of plates."
            ),
            QuizQuestion(
                questionText: "What does 'HTTP' stand for?",
                answers: ["HyperText Transfer Protocol", "HighText Transfer Protocol", "HyperText Transmission Process", "HyperTech Transfer Protocol"],
                correctAnswerIndex: 0, userAnswerIndex: nil, isFlagged: false,
                hint: "Standard protocol for documents."
            ),
            QuizQuestion(
                questionText: "What is the time complexity of a binary search?",
                answers: ["O(n)", "O(n^2)", "O(log n)", "O(1)"],
                correctAnswerIndex: 2, userAnswerIndex: nil, isFlagged: false,
                hint: "Halves space at each step."
            ),
            QuizQuestion(
                questionText: "Which is NOT a core concept of OOP?",
                answers: ["Encapsulation", "Polymorphism", "Compilation", "Inheritance"],
                correctAnswerIndex: 2, userAnswerIndex: nil, isFlagged: false,
                hint: "One is a build process."
            )
        ]
        
        // 2. Explanations (Must match order of questions above)
        explanations = [
            "A Stack adds and removes items from the same end (the top), following Last In, First Out (LIFO). Queues follow FIFO.",
            "HTTP stands for HyperText Transfer Protocol, which is the foundation of data communication for the World Wide Web.",
            "Binary search repeatedly divides the search interval in half. This process has a logarithmic time complexity O(log n).",
            "Compilation is the process of translating source code into object code. The 4 pillars of OOP are Encapsulation, Abstraction, Inheritance, and Polymorphism."
        ]
    }

    // MARK: - Timer & Logic (Standard)
    func initiateTimer() {
        sessionTimer?.invalidate()
        if totalSessionTime > 0 {
            secondsRemaining = totalSessionTime
            countdownLabel.isHidden = false
            refreshTimeLabel()
            sessionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
        } else {
            countdownLabel.isHidden = true
        }
    }
    
    @objc func timerTick() {
        if secondsRemaining > 0 {
            secondsRemaining -= 1
            refreshTimeLabel()
        } else {
            sessionTimer?.invalidate()
            finishSession()
        }
    }
    
    func refreshTimeLabel() {
        let minutes = Int(secondsRemaining) / 60
        let seconds = Int(secondsRemaining) % 60
        countdownLabel.text = String(format: "%02i:%02i", minutes, seconds)
    }

    // MARK: - UI Rendering
    func renderQuestion() {
        guard questionIndex < sessionQuestions.count else { return }
        let question = sessionQuestions[questionIndex]
        
        title = "Question \(questionIndex + 1)/\(sessionQuestions.count)"
        quizQuestionLabel.text = question.questionText
        updateFlagIcon()
        resetOptionStyles()
        
        if let savedIndex = question.userAnswerIndex {
            let selectedButton = optionButtons[savedIndex]
            selectedButton.backgroundColor = UIColor.systemGray4
            selectedButton.layer.borderColor = UIColor.systemBlue.cgColor
            selectedButton.layer.borderWidth = 2.0
        }
        
        backQButton.isHidden = (questionIndex == 0)
        forwardQButton.setTitle(questionIndex == sessionQuestions.count - 1 ? "Finish" : "Next", for: .normal)
        
        let prefixes = ["A.", "B.", "C.", "D."]
        for (index, button) in optionButtons.enumerated() {
            if index < question.answers.count {
                button.setTitle("\(prefixes[index]) \(question.answers[index])", for: .normal)
                button.isHidden = false
            } else { button.isHidden = true }
        }
    }
    
    // MARK: - Styling
        func styleOptionButtons() {
            for button in optionButtons {
                // 1. Reset configuration to ensure manual styling works (iOS 15+ fix)
                button.configuration = nil
                
                // 2. Border & Corner Styling
                button.layer.cornerRadius = 12
                button.layer.borderWidth = 1.0
                button.layer.borderColor = UIColor.systemGray4.cgColor
                button.backgroundColor = .clear
                button.setTitleColor(.label, for: .normal)
                
                // 3. ✅ LEFT ALIGNMENT FIX
                button.contentHorizontalAlignment = .left
                
                // 4. ✅ Add Padding (Top, Left, Bottom, Right)
                button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
                
                // 5. Text Handling (Optional: Handles long answers better)
                button.titleLabel?.numberOfLines = 2
                button.titleLabel?.lineBreakMode = .byTruncatingTail
            }
        }
    
    func resetOptionStyles() {
        for button in optionButtons {
            button.backgroundColor = .clear
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.layer.borderWidth = 1.0
        }
    }
    
    func configureNavBarItems() {
        if hintItem == nil {
            let hint = UIBarButtonItem(image: UIImage(systemName: "lightbulb"), style: .plain, target: self, action: #selector(showHintPressed))
            let flag = UIBarButtonItem(image: UIImage(systemName: "flag"), style: .plain, target: self, action: #selector(toggleFlagPressed))
            hintItem = hint; flagItem = flag
            navigationItem.rightBarButtonItems = [flag, hint]
        }
    }
    
    @objc func showHintPressed() {
        let q = sessionQuestions[questionIndex]
        let alert = UIAlertController(title: "Hint", message: q.hint, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc func toggleFlagPressed() {
        sessionQuestions[questionIndex].isFlagged.toggle()
        updateFlagIcon()
    }
    
    func updateFlagIcon() {
        guard let btn = flagItem else { return }
        let isFlagged = sessionQuestions[questionIndex].isFlagged
        btn.image = UIImage(systemName: isFlagged ? "flag.fill" : "flag")
        btn.tintColor = isFlagged ? .systemRed : .white
    }
    
    @IBAction func optionSelected(_ sender: UIButton) {
        resetOptionStyles()
        guard let idx = optionButtons.firstIndex(of: sender) else { return }
        sessionQuestions[questionIndex].userAnswerIndex = idx
        sender.backgroundColor = UIColor.systemGray4
        sender.layer.borderColor = UIColor.systemBlue.cgColor
        sender.layer.borderWidth = 2.0
    }
    
    @IBAction func prevQuestionPressed(_ sender: Any) {
        if questionIndex > 0 {
            questionIndex -= 1; renderQuestion()
        }
    }
    
    @IBAction func forwardButtonTapped(_ sender: UIButton) {
        if questionIndex < sessionQuestions.count - 1 {
            questionIndex += 1; renderQuestion()
        } else {
            finishSession()
        }
    }
    
    func finishSession() {
        sessionTimer?.invalidate()
        let results = calculateResults()
        performSegue(withIdentifier: "NavigateToResults", sender: results)
    }
    
    func calculateResults() -> FinalQuizResult {
        var score = 0
        var details: [QuestionResultDetail] = []
        for q in sessionQuestions {
            let correct = (q.userAnswerIndex == q.correctAnswerIndex)
            if correct { score += 1 }
            // Stub for details (we use summaryList instead)
             let detail = QuestionResultDetail(
                questionText: q.questionText, wasCorrect: correct,
                selectedAnswer: nil, correctAnswerFullText: "", isFlagged: q.isFlagged
            )
            details.append(detail)
        }
        return FinalQuizResult(finalScore: score, totalQuestions: sessionQuestions.count, timeElapsed: TimeInterval(totalSessionTime - secondsRemaining), sourceName: sourceName ?? "Quiz", details: details)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NavigateToResults" {
            if let dest = segue.destination as? QuizResultsViewController,
               let res = sender as? FinalQuizResult {
                
                dest.finalResult = res
                dest.topicToSave = self.currentTopic
                dest.parentFolder = self.parentSubject
                
                // ✅ CREATE SUMMARY LIST WITH EXPLANATIONS
                var list: [QuizSummaryItem] = []
                for (i, q) in sessionQuestions.enumerated() {
                    let expl = (i < explanations.count) ? explanations[i] : ""
                    let item = QuizSummaryItem(
                        questionText: q.questionText,
                        userAnswerIndex: q.userAnswerIndex,
                        correctAnswerIndex: q.correctAnswerIndex,
                        allOptions: q.answers,
                        explanation: expl,
                        isCorrect: (q.userAnswerIndex == q.correctAnswerIndex)
                    )
                    list.append(item)
                }
                dest.summaryData = list
            }
        }
    }
}
