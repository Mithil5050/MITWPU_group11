//
//  QuizViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 11/12/25.
//

import UIKit

class QuizViewController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet var answerButtons: [UIButton]!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var timerLabel: UILabel!
    
    // MARK: - Properties
    var quizTopic: Topic?
    var parentSubjectName: String?
    var allQuestions: [QuizQuestion] = []
    var selectedSourceName: String?
    var currentQuestionIndex = 0
    var score = 0
    
    private var hintBarItem: UIBarButtonItem?
    private var flagBarItem: UIBarButtonItem?
    private var countdownTimer: Timer?
    private let totalTime = 300
    private var timeRemaining = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialData()
        setupUI()
        displayQuestion()
        startTimer()
    }

    // MARK: - Setup Methods
    private func setupInitialData() {
        let quizName = selectedSourceName ?? quizTopic?.name ?? ""
        title = quizName
        
        let updatedQuestions = QuizManager.getQuestions(for: quizName)
        
        if !updatedQuestions.isEmpty {
            self.allQuestions = updatedQuestions
        } else if let contentBody = quizTopic?.largeContentBody, !contentBody.isEmpty {
            self.allQuestions = unpackQuestions(from: contentBody)
        }
    }

    private func setupUI() {
        setupAnswerButtons()
        setupNavigationBarButtons()
    }

    private func setupAnswerButtons() {
        for button in answerButtons {
            button.configuration = nil
            button.layer.cornerRadius = 12
            button.clipsToBounds = true
            button.layer.borderWidth = 1.0
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.backgroundColor = .clear
            button.setTitleColor(.label, for: .normal)
            button.contentHorizontalAlignment = .left
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        }
    }

    private func setupNavigationBarButtons() {
        // Refactored to use UIAction (Modern Swift Approach)
        let hintAction = UIAction(image: UIImage(systemName: "lightbulb")) { [weak self] _ in
            self?.showHint()
        }
        
        let flagAction = UIAction(image: UIImage(systemName: "flag")) { [weak self] _ in
            self?.toggleFlag()
        }
        
        hintBarItem = UIBarButtonItem(primaryAction: hintAction)
        flagBarItem = UIBarButtonItem(primaryAction: flagAction)
        
        navigationItem.rightBarButtonItems = [flagBarItem!, hintBarItem!]
    }

    // MARK: - Quiz Logic
    func displayQuestion() {
        guard currentQuestionIndex < allQuestions.count else {
            finishQuiz()
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
        
        previousButton.isHidden = (currentQuestionIndex == 0)
        let isLastQuestion = (currentQuestionIndex == allQuestions.count - 1)
        
        nextButton.setTitle(isLastQuestion ? "Finish" : "Next", for: .normal)
        
        nextButton.removeTarget(nil, action: nil, for: .allEvents)
        if isLastQuestion {
            nextButton.addTarget(self, action: #selector(finishQuizTapped), for: .touchUpInside)
        } else {
            nextButton.addTarget(self, action: #selector(goToNextQuestion), for: .touchUpInside)
        }
        
        let prefixes = ["A.", "B.", "C.", "D."]
        for (index, button) in answerButtons.enumerated() {
            button.setTitle("\(prefixes[index]) \(question.answers[index])", for: .normal)
        }
    }

    private func resetAnswerButtonAppearance() {
        for button in answerButtons {
            button.backgroundColor = .clear
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.layer.borderWidth = 1.0
            button.setTitleColor(.label, for: .normal)
            button.isEnabled = true
        }
    }

    // MARK: - Timer Logic
     func startTimer() {
        countdownTimer?.invalidate()
        if totalTime > 0 {
            timeRemaining = totalTime
            timerLabel.isHidden = false
            updateTimerLabel()
            // Timer MUST use @objc selector
            countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(handleTimerTick), userInfo: nil, repeats: true)
        }
    }

    @objc private func handleTimerTick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            updateTimerLabel()
        } else {
            countdownTimer?.invalidate()
            finishQuiz()
        }
    }

    private func updateTimerLabel() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        timerLabel.text = String(format: "%02i:%02i", minutes, seconds)
        
        if timeRemaining <= 10 {
            timerLabel.textColor = .systemRed
            timerLabel.font = .systemFont(ofSize: 14, weight: .bold)
        } else {
            timerLabel.textColor = .secondaryLabel
            timerLabel.font = .systemFont(ofSize: 14, weight: .medium)
        }
    }

    // MARK: - Actions
    @IBAction func answerTapped(_ sender: UIButton) {
        resetAnswerButtonAppearance()
        guard let tappedIndex = answerButtons.firstIndex(of: sender) else { return }
        
        allQuestions[currentQuestionIndex].userAnswerIndex = tappedIndex
        sender.backgroundColor = UIColor.systemGray4
        sender.layer.borderColor = UIColor.systemBlue.cgColor
        sender.layer.borderWidth = 2.0
    }

    @objc func goToNextQuestion() {
        currentQuestionIndex += 1
        displayQuestion()
    }

    @IBAction func previousButtonTapped(_ sender: Any) {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            displayQuestion()
        }
    }

    @objc func finishQuizTapped() {
        finishQuiz()
    }

    private func finishQuiz() {
        countdownTimer?.invalidate()
        let finalResults = processQuizResults()
        performSegue(withIdentifier: "ShowQuizResults", sender: finalResults)
    }

    private func showHint() {
        let currentQuestion = allQuestions[currentQuestionIndex]
        let alert = UIAlertController(title: "Hint", message: currentQuestion.hint, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }

    private func toggleFlag() {
        allQuestions[currentQuestionIndex].isFlagged.toggle()
        updateFlagButtonAppearance()
    }

    private func updateFlagButtonAppearance() {
        guard let flagButton = flagBarItem else { return }
        let isFlagged = allQuestions[currentQuestionIndex].isFlagged
        flagButton.image = UIImage(systemName: isFlagged ? "flag.fill" : "flag")
        flagButton.tintColor = isFlagged ? .systemRed : .systemGray
    }

    // MARK: - Data Processing
    private func processQuizResults() -> FinalQuizResult {
        var finalScore = 0
        var detailResults: [QuestionResultDetail] = []

        for question in allQuestions {
            let wasCorrect = (question.userAnswerIndex == question.correctAnswerIndex)
            if wasCorrect { finalScore += 1 }
            
            detailResults.append(QuestionResultDetail(
                questionText: question.questionText,
                wasCorrect: wasCorrect,
                selectedAnswer: question.userAnswerIndex.map { question.answers[$0] },
                correctAnswerFullText: question.answers[question.correctAnswerIndex],
                isFlagged: question.isFlagged
            ))
        }
        
        return FinalQuizResult(
            finalScore: finalScore,
            totalQuestions: allQuestions.count,
            timeElapsed: TimeInterval(totalTime - timeRemaining),
            sourceName: self.selectedSourceName ?? "Quiz",
            details: detailResults
        )
    }

    private func unpackQuestions(from content: String) -> [QuizQuestion] {
        let lines = content.components(separatedBy: "\n")
        return lines.compactMap { line in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 5 else { return nil }
            return QuizQuestion(
                questionText: parts[0],
                answers: [parts[1], parts[2], parts[3], parts[4]],
                correctAnswerIndex: parts.count > 5 ? (Int(parts[5]) ?? 0) : 0,
                userAnswerIndex: nil,
                isFlagged: false,
                hint: parts.count > 6 ? parts[6] : "Focus on core concepts."
            )
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowQuizResults",
           let resultsVC = segue.destination as? ResultsViewController,
           let results = sender as? FinalQuizResult {
            
            resultsVC.finalResult = results
            resultsVC.topicToSave = self.quizTopic
            resultsVC.parentFolder = self.parentSubjectName
            resultsVC.summaryData = self.allQuestions.map { q in
                QuizSummaryItem(
                    questionText: q.questionText,
                    userAnswerIndex: q.userAnswerIndex,
                    correctAnswerIndex: q.correctAnswerIndex,
                    allOptions: q.answers,
                    explanation: q.hint,
                    isCorrect: (q.userAnswerIndex == q.correctAnswerIndex)
                )
            }
        }
    }
}
