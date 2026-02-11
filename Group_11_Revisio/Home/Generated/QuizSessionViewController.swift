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
    var parentSubject: String?
    
    var sessionQuestions: [QuizQuestion] = []
    
    // PRESERVED: Explanations array
    var explanations: [String] = []
    
    var questionIndex = 0
    var sourceName: String? = "Quiz"
    
    // PRESERVED: UI bar items
    var hintItem: UIBarButtonItem?
    var flagItem: UIBarButtonItem?
    
    var sessionTimer: Timer?
    var totalSessionTime = 300
    var secondsRemaining = 0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = sourceName
        
        // Set background to black to match the "Image 2" dark mode look
        self.view.backgroundColor = .black
        
        loadData()
        styleOptionButtons() // ✅ Applies the new "Image 2" styling
        configureNavBarItems()
        renderQuestion()
        initiateTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionTimer?.invalidate()
    }
    
    // MARK: - Data Loading
    func loadData() {
        if let aiQuestions = currentTopic?.quizQuestions, !aiQuestions.isEmpty {
            self.sessionQuestions = aiQuestions
            print("🧠 Loaded \(aiQuestions.count) AI Questions.")
            self.explanations = aiQuestions.map { $0.hint ?? "No explanation available." }
        }
        else {
            print("⚠️ No AI questions found, loading hardcoded data...")
            loadDummyData()
        }
        
        if !sessionQuestions.isEmpty {
            totalSessionTime = sessionQuestions.count * 30
            secondsRemaining = totalSessionTime
        }
    }
    
    func loadDummyData() {
        let legacyName = sourceName?.replacingOccurrences(of: " Quiz", with: "") ?? ""
        self.sessionQuestions = QuizManager.getQuestions(for: legacyName)
        self.explanations = self.sessionQuestions.map { $0.hint ?? "" }
    }
    
    // MARK: - Timer Logic
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
    
    // MARK: - UI Rendering (✅ MATCHING IMAGE 2)
    func renderQuestion() {
        guard !sessionQuestions.isEmpty, questionIndex < sessionQuestions.count else { return }
        
        let q = sessionQuestions[questionIndex]
        let prefixes = ["A.", "B.", "C.", "D."] // Prefixes like Image 2
        
        // Question Text Styling
        quizQuestionLabel.textColor = .white
        quizQuestionLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium) // iOS System Font
        
        UIView.transition(with: quizQuestionLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.quizQuestionLabel.text = q.questionText
        }, completion: nil)
        
        let progress = Float(questionIndex + 1) / Float(sessionQuestions.count)
        progressBar.setProgress(progress, animated: true)
        progressBar.trackTintColor = .darkGray
        progressBar.progressTintColor = .systemBlue
        
        for (i, btn) in optionButtons.enumerated() {
            if i < q.answers.count {
                btn.isHidden = false
                
                // Add Prefix "A. Option Text"
                let prefix = (i < prefixes.count) ? prefixes[i] : ""
                let fullText = "\(prefix)   \(q.answers[i])"
                
                btn.setTitle(fullText, for: .normal)
                
                // ✅ DEFAULT STATE (Unselected) - Matches Image 2
                // Clear background, Grey Border, White Text
                btn.backgroundColor = .clear
                btn.layer.borderColor = UIColor.systemGray.cgColor
                btn.layer.borderWidth = 1
                btn.setTitleColor(.white, for: .normal)
                
                // ✅ SELECTED STATE
                // Highlight border blue, slight fill
                if let userIdx = q.userAnswerIndex, userIdx == i {
                    btn.layer.borderColor = UIColor.systemBlue.cgColor
                    btn.layer.borderWidth = 2
                    btn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
                }
            } else {
                btn.isHidden = true
            }
        }
        
        backQButton.isEnabled = (questionIndex > 0)
        forwardQButton.setTitle(questionIndex == sessionQuestions.count - 1 ? "Finish" : "Next", for: .normal)
    }
    
    // MARK: - Button Styling (✅ UPDATED FOR iOS LOOK)
    func styleOptionButtons() {
        for btn in optionButtons {
            // Shape
            btn.layer.cornerRadius = 16 // More rounded like Image 2
            
            // Alignment
            btn.contentHorizontalAlignment = .leading // Left Align
            
            // Padding (Critical for looking good)
            // Top/Bottom 16, Left/Right 20
            btn.contentEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
            
            // Font
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular) // iOS Standard Body
            
            // Multi-line support
            btn.titleLabel?.numberOfLines = 0
            btn.titleLabel?.lineBreakMode = .byWordWrapping
        }
        
        // Style Navigation Buttons (Pill shape, Dark Grey fill)
        let navButtons = [backQButton, forwardQButton]
        for btn in navButtons {
            btn?.layer.cornerRadius = 24 // Pill shape
            btn?.backgroundColor = UIColor(white: 0.15, alpha: 1.0) // Dark Grey Background
            btn?.setTitleColor(.white, for: .normal)
            btn?.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        }
    }
    
    func configureNavBarItems() {
        let flagImg = UIImage(systemName: "flag")
        flagItem = UIBarButtonItem(image: flagImg, style: .plain, target: self, action: #selector(toggleFlag))
        
        let hintImg = UIImage(systemName: "lightbulb")
        hintItem = UIBarButtonItem(image: hintImg, style: .plain, target: self, action: #selector(showHint))
        
        navigationItem.rightBarButtonItems = [flagItem!, hintItem!]
        navigationController?.navigationBar.tintColor = .white
    }
    
    // MARK: - Actions
    
    @IBAction func optionSelected(_ sender: UIButton) {
        guard let index = optionButtons.firstIndex(of: sender) else { return }
        sessionQuestions[questionIndex].userAnswerIndex = index
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        renderQuestion()
    }
    
    @IBAction func forwardButtonTapped(_ sender: UIButton) {
        if questionIndex < sessionQuestions.count - 1 {
            questionIndex += 1
        } else {
            finishQuiz()
            return
        }
        renderQuestion()
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        if questionIndex > 0 {
            questionIndex -= 1
        }
        renderQuestion()
    }
    
    @objc func toggleFlag() {
        sessionQuestions[questionIndex].isFlagged.toggle()
    }
    
    @objc func showHint() {
        let hintText = sessionQuestions[questionIndex].hint ?? "No hint available."
        let alert = UIAlertController(title: "Hint", message: hintText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
            
            let detail = QuestionResultDetail(
                questionText: question.questionText,
                wasCorrect: isCorrect,
                selectedAnswer: (question.userAnswerIndex != nil) ? question.answers[question.userAnswerIndex!] : "No Answer",
                correctAnswerFullText: question.answers[question.correctAnswerIndex],
                isFlagged: question.isFlagged
            )
            details.append(detail)
            
            let expl = (i < explanations.count) ? explanations[i] : (question.hint ?? "")
            
            let summary = QuizSummaryItem(
                questionText: question.questionText,
                userAnswerIndex: question.userAnswerIndex,
                correctAnswerIndex: question.correctAnswerIndex,
                allOptions: question.answers,
                explanation: expl,
                isCorrect: isCorrect
            )
            summaryItems.append(summary)
        }
        
        let newAttempt = QuizAttempt(
            id: UUID(),
            date: Date(),
            score: score,
            totalQuestions: sessionQuestions.count,
            summaryData: "Score: \(score)/\(sessionQuestions.count)"
        )
        
        saveAttemptToTopic(attempt: newAttempt)
        
        let timeSpent = totalSessionTime - secondsRemaining
        let finalResult = FinalQuizResult(
            finalScore: score,
            totalQuestions: sessionQuestions.count,
            timeElapsed: TimeInterval(timeSpent),
            sourceName: sourceName ?? "Quiz",
            details: details
        )
        
        performSegue(withIdentifier: "MapsToResults", sender: (finalResult, summaryItems))
    }
    
    func saveAttemptToTopic(attempt: QuizAttempt) {
        guard var topic = currentTopic else { return }
        
        if topic.attempts == nil { topic.attempts = [] }
        topic.attempts?.append(attempt)
        
        DataManager.shared.updateTopic(subjectName: parentSubject ?? "General Study", topic: topic)
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
