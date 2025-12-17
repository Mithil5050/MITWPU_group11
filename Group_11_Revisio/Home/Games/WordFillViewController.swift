//
//  Question.swift
//  MITWPU_group11 
//
//  Created by Mithil on 17/12/25.
//


import UIKit

struct Question {
    let text: String
    let options: [String]
    let correctAnswer: String
}

class WordFillViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel! // e.g., "Question 1/10"
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var questionLabel: UILabel!
    
    // Connect these to your 4 option buttons
    @IBOutlet var optionButtons: [UIButton]!
    @IBOutlet weak var actionButton: UIButton! // The "Submit" or "Next" button

    // MARK: - Properties
    private var questions: [Question] = []
    private var currentQuestionIndex = 0
    private var timer: Timer?
    private var secondsRemaining = 60
    private var selectedAnswer: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupQuestions()
        setupUI()
        loadQuestion()
        startTimer()
    }

    // MARK: - Setup
    private func setupQuestions() {
        questions = [
            Question(text: "A column, or set of columns, that uniquely identifies every tuple in a relation is formally known as a ________", 
                     options: ["Candidate Key", "Super Key", "Primary Key", "Foreign Key"], 
                     correctAnswer: "Super Key"),
            Question(text: "The ACID property that guarantees committed changes remain permanently recorded is called ________", 
                     options: ["Atomicity", "Consistency", "Isolation", "Durability"], 
                     correctAnswer: "Durability")
        ]
    }

    private func setupUI() {
        // Apply modern iOS styling
        actionButton.layer.cornerRadius = 12
        for button in optionButtons {
            button.layer.cornerRadius = 20
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray5.cgColor
        }
    }

    // MARK: - Game Logic
    private func loadQuestion() {
        let currentQuestion = questions[currentQuestionIndex]
        questionLabel.text = currentQuestion.text
        progressLabel.text = "Question \(currentQuestionIndex + 1)/\(questions.count)"
        progressView.setProgress(Float(currentQuestionIndex + 1) / Float(questions.count), animated: true)
        
        // Reset buttons and assign options
        selectedAnswer = nil
        for (index, button) in optionButtons.enumerated() {
            button.setTitle(currentQuestion.options[index], for: .normal)
            button.backgroundColor = .systemBackground
            button.tintColor = .label
        }
        
        // Update Action Button
        actionButton.setTitle(currentQuestionIndex == questions.count - 1 ? "End" : "Submit", for: .normal)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
                self.updateTimerLabel()
            } else {
                self.timer?.invalidate()
                self.showFeedbackPopup(isCorrect: false, title: "Time's Up!", message: "You ran out of time.")
            }
        }
    }

    private func updateTimerLabel() {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Actions
    @IBAction func optionTapped(_ sender: UIButton) {
        // Highlight selected button
        for button in optionButtons {
            button.backgroundColor = .systemBackground
        }
        sender.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        selectedAnswer = sender.titleLabel?.text
    }

    @IBAction func submitTapped(_ sender: UIButton) {
        guard let answer = selectedAnswer else { return }
        
        let isCorrect = (answer == questions[currentQuestionIndex].correctAnswer)
        
        if isCorrect {
            showFeedbackPopup(isCorrect: true, title: "Correct!", message: "That is the right answer.")
        } else {
            showFeedbackPopup(isCorrect: false, title: "Incorrect", message: "Please try again.")
        }
    }

    private func showFeedbackPopup(isCorrect: Bool, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Continue", style: .default) { _ in
            if self.currentQuestionIndex < self.questions.count - 1 {
                self.currentQuestionIndex += 1
                self.loadQuestion()
            } else {
                // Handle Game Completion
                self.timer?.invalidate()
                self.questionLabel.text = "Quiz Completed!"
            }
        }
        
        alert.addAction(action)
        present(alert, animated: true)
    }
}