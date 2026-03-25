import UIKit

class QuizViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet var answerButtons: [UIButton]!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    var quizTopic: Topic?
    var parentSubjectName: String?
    var allQuestions: [QuizQuestion] = []
    var selectedSourceName: String?
    var currentQuestionIndex = 0
    var score = 0
    
    var timeLimitInMinutes: Int = 15
    private var countdownTimer: Timer?
    private var timeRemaining = 0

    private var hintBarItem: UIBarButtonItem?
    private var flagBarItem: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialData()
        setupUI()
        displayQuestion()
        startTimer()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    private func setupInitialData() {
        let rawQuizName = selectedSourceName ?? quizTopic?.name ?? "Quiz"
        
        // ✅ LOGIC CHANGE: Smart Naming for Navigation Title
        let cleanTitle = rawQuizName.replacingOccurrences(of: ".txt", with: "")
                                   .replacingOccurrences(of: "Note_", with: "")
                                   .replacingOccurrences(of: "Link_", with: "")
                                   .replacingOccurrences(of: "_", with: " ")
                                   .trimmingCharacters(in: .whitespaces)
        
        // This sets the base title; note that displayQuestion() overrides this with "Question X"
        self.title = cleanTitle
        
        let updatedQuestions = QuizManager.getQuestions(for: rawQuizName)
        
        if !updatedQuestions.isEmpty {
            self.allQuestions = updatedQuestions
        } else if let quizQuestions = quizTopic?.quizQuestions, !quizQuestions.isEmpty {
            self.allQuestions = quizQuestions
        } else if let contentBody = quizTopic?.largeContentBody, !contentBody.isEmpty {
            self.allQuestions = unpackQuestions(from: contentBody)
        }
    }

    private func setupUI() {
        // ✅ LOGIC CHANGE: Fix Question Label Word Wrapping
        questionLabel.numberOfLines = 0
        questionLabel.lineBreakMode = .byWordWrapping
        
        setupAnswerButtons()
        setupNavigationBarButtons()
        progressBar.progress = 0.0
        progressBar.progressTintColor = .systemBlue
        progressBar.trackTintColor = .systemGray5
    }

    private func setupAnswerButtons() {
        for button in answerButtons {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            config.titleAlignment = .leading
            button.configuration = config
            
            // ✅ LOGIC CHANGE: Fix Answer Button Word Wrapping
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
        let alert = UIAlertController(title: "Quit Quiz?", message: "Your progress will be lost. Are you sure?", preferredStyle: .alert)
        let quitAction = UIAlertAction(title: "Quit", style: .destructive) { [weak self] _ in
            self?.countdownTimer?.invalidate()
            self?.navigationController?.popViewController(animated: true)
        }
        alert.addAction(quitAction)
        alert.addAction(UIAlertAction(title: "Resume", style: .cancel))
        present(alert, animated: true)
    }

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
        nextButton.addTarget(self, action: isLastQuestion ? #selector(finishQuizTapped) : #selector(goToNextQuestion), for: .touchUpInside)
        
        let prefixes = ["A.", "B.", "C.", "D."]
        for (index, button) in answerButtons.enumerated() {
            button.setTitle("\(prefixes[index]) \(question.answers[index])", for: .normal)
            button.contentHorizontalAlignment = .leading
            button.invalidateIntrinsicContentSize()
        }
    }

    private func resetAnswerButtonAppearance() {
        for button in answerButtons {
            button.backgroundColor = .clear
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.layer.borderWidth = 1.0
            button.isEnabled = true
        }
    }

    func startTimer() {
        countdownTimer?.invalidate()
        timeRemaining = timeLimitInMinutes * 60
        timerLabel.isHidden = false
        updateTimerLabel()
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(handleTimerTick), userInfo: nil, repeats: true)
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
        timerLabel.textColor = timeRemaining <= 10 ? .systemRed : .label
    }

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
        let alert = UIAlertController(title: "Hint", message: allQuestions[currentQuestionIndex].hint, preferredStyle: .alert)
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

    private func processQuizResults() -> FinalQuizResult {
        var finalScore = 0
        var detailResults: [QuestionResultDetail] = []
        for question in allQuestions {
            let wasCorrect = (question.userAnswerIndex == question.correctAnswerIndex)
            if wasCorrect { finalScore += 1 }
            detailResults.append(QuestionResultDetail(questionText: question.questionText, wasCorrect: wasCorrect, selectedAnswer: question.userAnswerIndex.map { question.answers[$0] }, correctAnswerFullText: question.answers[question.correctAnswerIndex], isFlagged: question.isFlagged))
        }
        let elapsed = TimeInterval((timeLimitInMinutes * 60) - timeRemaining)
        return FinalQuizResult(finalScore: finalScore, totalQuestions: allQuestions.count, timeElapsed: elapsed, sourceName: self.selectedSourceName ?? "Quiz", details: detailResults)
    }

    private func unpackQuestions(from content: String) -> [QuizQuestion] {
        let lines = content.components(separatedBy: "\n")
        return lines.compactMap { line in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 6 else { return nil }
            return QuizQuestion(questionText: parts[0], answers: [parts[1], parts[2], parts[3], parts[4]], correctAnswerIndex: Int(parts[5]) ?? 0, userAnswerIndex: nil, isFlagged: false, hint: parts.count > 6 ? parts[6] : "Focus on core concepts.")
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowQuizResults", let resultsVC = segue.destination as? ResultsViewController, let results = sender as? FinalQuizResult {
            resultsVC.finalResult = results
            resultsVC.topicToSave = self.quizTopic
            resultsVC.parentFolder = self.parentSubjectName
            resultsVC.summaryData = self.allQuestions.map { q in
                QuizSummaryItem(questionText: q.questionText, userAnswerIndex: q.userAnswerIndex, correctAnswerIndex: q.correctAnswerIndex, allOptions: q.answers, explanation: q.hint, isCorrect: (q.userAnswerIndex == q.correctAnswerIndex))
            }
        }
    }
}
