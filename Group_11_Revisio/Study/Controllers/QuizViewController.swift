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
    
    @IBOutlet weak var progressBar: UIProgressView!
    
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
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
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
        
        
        progressBar.progress = 0.0
       
        progressBar.progressTintColor = .systemBlue
        progressBar.trackTintColor = .systemGray5
    }

    private func setupAnswerButtons() {
        for button in answerButtons {
            // Use Plain configuration to allow automatic resizing
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            config.titleAlignment = .leading
            button.configuration = config

          
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.lineBreakMode = .byWordWrapping
            
           
            button.layer.cornerRadius = 12
            button.layer.borderWidth = 1.0
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.backgroundColor = .clear
            button.setTitleColor(.label, for: .normal)
        }
    }

    private func setupNavigationBarButtons() {
        // NEW: Custom Back Button for Exit Warning
        let backAction = UIAction { [weak self] _ in
            self?.showExitWarning()
        }
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), primaryAction: backAction)
        navigationItem.leftBarButtonItem = backButton

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
    private func showExitWarning() {
        let alert = UIAlertController(
            title: "Quit Quiz?",
            message: "Your progress for this attempt will be lost. Are you sure you want to Quit?",
            preferredStyle: .alert
        )
        
        let quitAction = UIAlertAction(title: "Quit", style: .destructive) { [weak self] _ in
            self?.countdownTimer?.invalidate()
            self?.navigationController?.popViewController(animated: true)
        }
        
        let resumeAction = UIAlertAction(title: "Resume", style: .cancel, handler: nil)
        
        alert.addAction(quitAction)
        alert.addAction(resumeAction)
        
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Quiz Logic
    func displayQuestion() {
        guard currentQuestionIndex < allQuestions.count else {
            finishQuiz()
            return
        }

        let question = allQuestions[currentQuestionIndex]
        
        title = "Question \(currentQuestionIndex + 1)"
        
        let progress = Float(currentQuestionIndex + 1) / Float(allQuestions.count)
        progressBar.setProgress(progress, animated: true)
        
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
            let fullText = "\(prefixes[index]) \(question.answers[index])"
            button.setTitle(fullText, for: .normal)
            
            // --- Alignment & Wrapping Fixes ---
            button.contentHorizontalAlignment = .leading // 👈 Forces Left Alignment
            button.titleLabel?.numberOfLines = 0         // 👈 Enables multi-line support
            button.titleLabel?.lineBreakMode = .byWordWrapping
            
            // Forces the button to re-calculate its height for the new text
            button.invalidateIntrinsicContentSize()
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
            timerLabel.textColor = .label
            timerLabel.font = UIFont.preferredFont(forTextStyle: .headline)
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
            // Check for at least 6 parts: Question (0), 4 Answers (1-4), CorrectIdx (5)
            guard parts.count >= 6 else { return nil }
            
            return QuizQuestion(
                questionText: parts[0],
                answers: [parts[1], parts[2], parts[3], parts[4]],
                correctAnswerIndex: Int(parts[5]) ?? 0,
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
                    userAnswerIndex: q.userAnswerIndex, // <--- IMPORTANT: NOT NIL
                    correctAnswerIndex: q.correctAnswerIndex,
                    allOptions: q.answers,
                    explanation: q.hint,
                    isCorrect: (q.userAnswerIndex == q.correctAnswerIndex)
                )
            }
        }
    }
}
