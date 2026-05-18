import UIKit

class QuizSessionViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var quizQuestionLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet var optionButtons: [UIButton]!
    @IBOutlet weak var backQButton: UIButton!
    @IBOutlet weak var forwardQButton: UIButton!
    @IBOutlet weak var countdownLabel: UILabel!

    // MARK: - Properties
    var currentTopic: Topic?
    var parentSubject: String = "General Study"

    var sessionQuestions: [QuizQuestion] = []
    var explanations: [String] = []

    var questionIndex = 0
    var sourceName: String = "Quiz"

    var hintItem: UIBarButtonItem?
    var flagItem: UIBarButtonItem?

    var sessionTimer: Timer?
    var totalSessionTime = 300
    var secondsRemaining = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Multi-line title so long names never truncate
        let titleLabel = UILabel()
        titleLabel.text = sourceName
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel

        self.view.backgroundColor = .black

        loadData()

        // Resume from saved progress if not completed
        if let savedProgress = currentTopic?.currentProgressIndex,
           let total = currentTopic?.totalItemsCount,
           savedProgress < total {
            questionIndex = savedProgress
        } else {
            questionIndex = 0
        }

        styleOptionButtons()
        configureNavBarItems()
        renderQuestion()
        initiateTimer()

        // ✅ Disable swipe-to-go-back so they can't bypass the warning
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionTimer?.invalidate()

        // Save current progress before quitting
        if var topic = currentTopic, !sessionQuestions.isEmpty {
            topic.currentProgressIndex = questionIndex
            topic.totalItemsCount = sessionQuestions.count
            DataManager.shared.updateTopic(subjectName: parentSubject, topic: topic)
        }

        // ✅ Re-enable swipe-to-go-back for the rest of the app
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    // MARK: - Data Loading
    func loadData() {
        if let aiQuestions = currentTopic?.quizQuestions, !aiQuestions.isEmpty {
            self.sessionQuestions = aiQuestions
            self.explanations = aiQuestions.map { $0.hint }
        } else {
            self.sessionQuestions = []
        }

        if !sessionQuestions.isEmpty {
            totalSessionTime = sessionQuestions.count * 30
            secondsRemaining = totalSessionTime
        } else {
            backQButton.isEnabled = false
            forwardQButton.isEnabled = false
            quizQuestionLabel.text = "No questions loaded."
        }
    }

    // MARK: - Timer
    func initiateTimer() {
        secondsRemaining = totalSessionTime
        updateTimerLabel()

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
                self.updateTimerLabel()
            } else {
                self.sessionTimer?.invalidate()
                self.finishQuiz()
            }
        }
    }

    func updateTimerLabel() {
        let min = secondsRemaining / 60
        let sec = secondsRemaining % 60
        countdownLabel.text = String(format: "%02d:%02d", min, sec)
        countdownLabel.textColor = (secondsRemaining < 30) ? .systemRed : .white
    }

    // MARK: - Rendering
    func renderQuestion() {
        guard !sessionQuestions.isEmpty, questionIndex < sessionQuestions.count else { return }

        let q = sessionQuestions[questionIndex]
        let prefixes = ["A.", "B.", "C.", "D."]

        quizQuestionLabel.text = q.questionText

        let progress = Float(questionIndex + 1) / Float(sessionQuestions.count)
        progressBar.setProgress(progress, animated: true)

        for (i, btn) in optionButtons.enumerated() {
            if i < q.answers.count {
                btn.isHidden = false
                let prefix = (i < prefixes.count) ? prefixes[i] : ""
                btn.setTitle("\(prefix)   \(q.answers[i])", for: .normal)

                if let userIdx = q.userAnswerIndex, userIdx == i {
                    btn.layer.borderColor = UIColor.systemBlue.cgColor
                    btn.layer.borderWidth = 2
                    btn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
                } else {
                    btn.layer.borderColor = UIColor.systemGray.cgColor
                    btn.layer.borderWidth = 1
                    btn.backgroundColor = .clear
                }
            } else {
                btn.isHidden = true
            }
        }

        backQButton.isEnabled = (questionIndex > 0)
        forwardQButton.setTitle(questionIndex == sessionQuestions.count - 1 ? "Finish" : "Next", for: .normal)
    }

    // MARK: - Styling
    func styleOptionButtons() {
        for btn in optionButtons {
            btn.layer.cornerRadius = 16
            btn.contentHorizontalAlignment = .leading
            // Use configuration insets instead of deprecated contentEdgeInsets
            var config = btn.configuration ?? UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
            btn.configuration = config
            btn.titleLabel?.numberOfLines = 0
        }
        backQButton.layer.cornerRadius = 24
        forwardQButton.layer.cornerRadius = 24
    }

    func configureNavBarItems() {
        // ✅ Custom Back Button that triggers the Exit Warning
        let backAction = UIAction { [weak self] _ in
            self?.showExitWarning()
        }
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), primaryAction: backAction)
        navigationItem.leftBarButtonItem = backButton

        let flagImg = UIImage(systemName: "flag")
        flagItem = UIBarButtonItem(image: flagImg, style: .plain, target: self, action: #selector(toggleFlag))
        let hintImg = UIImage(systemName: "lightbulb")
        hintItem = UIBarButtonItem(image: hintImg, style: .plain, target: self, action: #selector(showHint))
        navigationItem.rightBarButtonItems = [flagItem!, hintItem!]
    }

    // MARK: - Actions
    @IBAction func optionSelected(_ sender: UIButton) {
        guard let index = optionButtons.firstIndex(of: sender) else { return }
        sessionQuestions[questionIndex].userAnswerIndex = index
        renderQuestion()
    }

    @IBAction func forwardButtonTapped(_ sender: UIButton) {
        if questionIndex < sessionQuestions.count - 1 {
            questionIndex += 1
            renderQuestion()
        } else {
            finishQuiz()
        }
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        if questionIndex > 0 {
            questionIndex -= 1
            renderQuestion()
        }
    }

    @objc func toggleFlag() {
        sessionQuestions[questionIndex].isFlagged.toggle()
    }

    @objc func showHint() {
        let hintText = sessionQuestions[questionIndex].hint
        let alert = UIAlertController(title: "Hint", message: hintText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // ✅ Exit Warning Pop-up
    private func showExitWarning() {
        let alert = UIAlertController(
            title: "Quit Quiz?",
            message: "Your progress for this attempt will be lost. Are you sure you want to Quit?",
            preferredStyle: .alert
        )

        let resumeAction = UIAlertAction(title: "Resume", style: .cancel, handler: nil)

        let quitAction = UIAlertAction(title: "Quit", style: .destructive) { [weak self] _ in
            self?.sessionTimer?.invalidate()
            self?.navigationController?.popViewController(animated: true)
        }

        alert.addAction(resumeAction)
        alert.addAction(quitAction)

        present(alert, animated: true, completion: nil)
    }

    // MARK: - Finish & Save
    func finishQuiz() {
        sessionTimer?.invalidate()

        var score = 0
        var details: [QuestionResultDetail] = []
        var summaryItems: [QuizSummaryItem] = []

        for (i, question) in sessionQuestions.enumerated() {
            let isCorrect = (question.userAnswerIndex == question.correctAnswerIndex)
            if isCorrect { score += 1 }

            let expl = (i < explanations.count) ? explanations[i] : question.hint

            let summary = QuizSummaryItem(
                questionText: question.questionText,
                userAnswerIndex: question.userAnswerIndex,
                correctAnswerIndex: question.correctAnswerIndex,
                allOptions: question.answers,
                explanation: expl,
                isCorrect: isCorrect
            )
            summaryItems.append(summary)

            let detail = QuestionResultDetail(
                questionText: question.questionText,
                wasCorrect: isCorrect,
                selectedAnswer: (question.userAnswerIndex != nil) ? question.answers[question.userAnswerIndex!] : "No Answer",
                correctAnswerFullText: question.answers[question.correctAnswerIndex],
                isFlagged: question.isFlagged
            )
            details.append(detail)
        }

        let serializedData = summaryItems.map { item in
            var opts = item.allOptions
            while opts.count < 4 { opts.append("-") }
            let optsString = opts.prefix(4).joined(separator: "|")
            let uIdx = item.userAnswerIndex ?? -1
            return "\(item.questionText)|\(optsString)|\(item.correctAnswerIndex)|\(item.explanation)|\(uIdx)"
        }.joined(separator: "\n")

        let newAttempt = QuizAttempt(
            id: UUID(),
            date: Date(),
            score: score,
            totalQuestions: sessionQuestions.count,
            summaryData: serializedData
        )

        saveAttemptToTopic(attempt: newAttempt)

        let timeSpent = totalSessionTime - secondsRemaining
        let finalResult = FinalQuizResult(
            finalScore: score,
            totalQuestions: sessionQuestions.count,
            timeElapsed: TimeInterval(timeSpent),
            sourceName: sourceName,
            details: details
        )

        performSegue(withIdentifier: "MapsToResults", sender: (finalResult, summaryItems))
    }

    func saveAttemptToTopic(attempt: QuizAttempt) {
        guard var topic = currentTopic else { return }

        if topic.attempts == nil { topic.attempts = [] }
        topic.attempts?.append(attempt)

        topic.lastAccessed = "Score: \(attempt.score)/\(attempt.totalQuestions)"
        topic.currentProgressIndex = sessionQuestions.count
        topic.totalItemsCount = sessionQuestions.count

        self.currentTopic = topic

        DataManager.shared.updateTopic(subjectName: parentSubject, topic: topic)
        print("✅ Saved Quiz Attempt: \(attempt.score)")
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MapsToResults" {
            if let dest = segue.destination as? QuizResultsViewController,
               let data = sender as? (FinalQuizResult, [QuizSummaryItem]) {

                dest.finalResult = data.0
                dest.summaryData = data.1
                dest.topicToSave = self.currentTopic
                dest.parentFolder = self.parentSubject
            }
        }
    }
}
