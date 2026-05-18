import UIKit

// MARK: - AI Models
struct AIWordFillResponse: Codable {
    struct AIWordFillQuestion: Codable {
        let text: String
        let options: [String]
        let correctAnswer: String
    }
    let questions: [AIWordFillQuestion]
}

struct Question {
    let text: String
    let options: [String]
    let correctAnswer: String
}

// MARK: - View Controller
class WordFillViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var questionLabel: UILabel!

    @IBOutlet var optionButtons: [UIButton]!
    @IBOutlet var Gamecard: UIView!

    // MARK: - Properties
    var currentTopic: Topic? // ✅ Passed from Launch Screen

    private var questions: [Question] = []
    private var currentQuestionIndex = 0
    private var timer: Timer?
    private var secondsRemaining = 60
    private var isProcessingAnswer = false
    private var userAnswers: [String?] = []

    // Loading UI
    private lazy var loadingOverlayView = GameLoadingOverlayView(
        title: "Crafting your Word Fill from \(currentTopic?.name ?? "General Knowledge")...",
        subtitle: "AI is generating your questions"
    )

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        installQuitConfirmation() // ✅ Guard against accidental exits
        setupUI()
        setupLoadingOverlay()
        generateWordFill() // ✅ Calls AI before starting timer
    }

    // MARK: - Setup
    private func setupUI() {
        if let topicName = currentTopic?.name {
            self.title = "Word Fill: \(topicName)"
        } else {
            self.title = "Word Fill"
        }

        // MARK: Card Style
        Gamecard.layer.cornerRadius = 24
        Gamecard.layer.cornerCurve = .continuous
        Gamecard.backgroundColor = UIColor(red: 145/255, green: 193/255, blue: 239/255, alpha: 1.0)

        // MARK: Button Style
        for button in optionButtons {
            button.layer.cornerRadius = 20
            button.layer.cornerCurve = .continuous
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray5.cgColor
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
        }
    }

    private func setupLoadingOverlay() {
        loadingOverlayView.show(in: view)
    }

    // MARK: - ✅ AI GENERATION LOGIC
    private func generateWordFill() {
        Task {
            let contentBody = currentTopic?.largeContentBody ?? currentTopic?.notesContent ?? currentTopic?.cheatsheetContent ?? ""
            let safeContent = String(contentBody.prefix(15000))

            let prompt = """
            Create a "Word Fill" (fill-in-the-blank) game based on the following study material.
            Generate EXACTLY 5 fill-in-the-blank questions.
            Each question MUST have a sentence with a "________" (blank) where the missing word goes.
            Provide exactly 4 multiple choice options, with one being the exact correct answer.

            STRICTLY use this EXACT JSON format (do not add conversational text or markdown):
            {
              "questions": [
                {
                  "text": "The process of ________ is used by plants to make food.",
                  "options": ["Photosynthesis", "Respiration", "Digestion", "Osmosis"],
                  "correctAnswer": "Photosynthesis"
                }
              ]
            }

            STUDY MATERIAL:
            \(safeContent.isEmpty ? "General educational facts and trivia." : safeContent)
            """

            do {
                let jsonResponse = try await AIContentManager.shared.generateContent(
                    topic: prompt,
                    type: "Word Fill",
                    count: 5,
                    difficulty: "Medium"
                )

                let cleanJSON = cleanJSONText(jsonResponse)
                guard let data = cleanJSON.data(using: .utf8) else { throw URLError(.cannotDecodeContentData) }

                let decoder = JSONDecoder()
                let result = try decoder.decode(AIWordFillResponse.self, from: data)

                self.questions = result.questions.map {
                    Question(text: $0.text, options: $0.options, correctAnswer: $0.correctAnswer)
                }
                self.userAnswers = Array(repeating: nil, count: self.questions.count)

                DispatchQueue.main.async {
                    self.hideLoadingAndStartGame()
                }

            } catch {
                print("⚠️ AI Word Fill Failed: \(error.localizedDescription). Using fallback.")
                DispatchQueue.main.async {
                    self.loadFallbackQuestions()
                    self.hideLoadingAndStartGame()
                }
            }
        }
    }

    private func cleanJSONText(_ json: String) -> String {
        var clean = json
        if clean.contains("```json") { clean = clean.replacingOccurrences(of: "```json", with: "") }
        clean = clean.replacingOccurrences(of: "```", with: "")
        if let startIndex = clean.firstIndex(of: "{") { clean = String(clean[startIndex...]) }
        if let endIndex = clean.lastIndex(of: "}") { clean = String(clean[...endIndex]) }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadFallbackQuestions() {
        questions = [
            Question(text: "A column that uniquely identifies every tuple in a relation is known as a ________",
                     options: ["Candidate Key", "Super Key", "Primary Key", "Foreign Key"],
                     correctAnswer: "Super Key"),
            Question(text: "The ACID property that guarantees committed changes remain permanently recorded is called ________",
                     options: ["Atomicity", "Consistency", "Isolation", "Durability"],
                     correctAnswer: "Durability"),
            Question(text: "In a database, a ________ is a column that creates a link between data in two tables.",
                     options: ["Primary Key", "Composite Key", "Foreign Key", "Unique Key"],
                     correctAnswer: "Foreign Key"),
            Question(text: "The process of organizing data to minimize redundancy is known as Data ________",
                     options: ["Normalization", "Indexing", "Abstraction", "Encapsulation"],
                     correctAnswer: "Normalization"),
            Question(text: "Which SQL command is used to remove all records from a table without deleting the structure?",
                     options: ["DELETE", "DROP", "REMOVE", "TRUNCATE"],
                     correctAnswer: "TRUNCATE")
        ]
        userAnswers = Array(repeating: nil, count: questions.count)
    }

    private func hideLoadingAndStartGame() {
        loadingOverlayView.hide {
            self.loadQuestion()
            self.startTimer()
        }
    }

    private func loadQuestion() {
        guard !questions.isEmpty else { return }
        isProcessingAnswer = false
        let currentQuestion = questions[currentQuestionIndex]

        questionLabel.text = currentQuestion.text
        progressLabel.text = "Question \(currentQuestionIndex + 1)/\(questions.count)"
        progressView.setProgress(Float(currentQuestionIndex + 1) / Float(questions.count), animated: true)

        for (index, button) in optionButtons.enumerated() {
            if index < currentQuestion.options.count {
                button.setTitle(currentQuestion.options[index], for: .normal)
                button.isHidden = false
            } else {
                button.isHidden = true
            }

            // MARK: - RESET STATE
            button.backgroundColor = .systemBackground
            button.setTitleColor(.label, for: .normal)
            button.layer.borderColor = UIColor.systemGray5.cgColor
            button.layer.borderWidth = 1
            button.isEnabled = true
        }
    }

    // MARK: - Actions
    @IBAction func optionTapped(_ sender: UIButton) {
        guard !isProcessingAnswer else { return }
        isProcessingAnswer = true

        guard let userAnswer = sender.titleLabel?.text else { return }
        let currentQuestion = questions[currentQuestionIndex]
        let correctAnswer = currentQuestion.correctAnswer

        userAnswers[currentQuestionIndex] = userAnswer

        optionButtons.forEach { $0.isEnabled = false }

        // MARK: - SELECTION STYLE
        sender.backgroundColor = .clear
        sender.setTitleColor(.white, for: .normal)
        sender.layer.borderWidth = 3

        if userAnswer == correctAnswer {
            sender.layer.borderColor = UIColor.systemGreen.cgColor
        } else {
            sender.layer.borderColor = UIColor.systemRed.cgColor
            highlightCorrectAnswer(correctAnswer)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.moveToNextQuestion()
        }
    }

    private func highlightCorrectAnswer(_ answer: String) {
        for button in optionButtons {
            if button.titleLabel?.text == answer {
                button.backgroundColor = .clear
                button.setTitleColor(.white, for: .normal)
                button.layer.borderColor = UIColor.systemGreen.cgColor
                button.layer.borderWidth = 3
            }
        }
    }

    // MARK: - Navigation
    private func moveToNextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            loadQuestion()
        } else {
            showFinalResults()
        }
    }

    private func showFinalResults() {

        ProgressDataManager.shared.totalWordFillsDone += 1
        timer?.invalidate()

        let (result, summaryItems) = processQuizData()

        // Award XP
        Task { await RevisioManager.shared.earnXP(amount: 15, reason: "Played Word Fill") }
        let elapsed = Double(60 - secondsRemaining) / 60.0
        ProgressDataManager.shared.logSession(minutes: max(elapsed, 1.0), category: "Games")

        performSegue(withIdentifier: "NavigateToResults", sender: (result, summaryItems))
    }

    private func processQuizData() -> (FinalQuizResult, [QuizSummaryItem]) {
        var score = 0
        var details: [QuestionResultDetail] = []
        var summaryItems: [QuizSummaryItem] = []

        for (index, question) in questions.enumerated() {
            let userAnswerText = userAnswers[index]
            let isCorrect = (userAnswerText == question.correctAnswer)

            if isCorrect { score += 1 }

            let detail = QuestionResultDetail(
                questionText: question.text,
                wasCorrect: isCorrect,
                selectedAnswer: userAnswerText,
                correctAnswerFullText: question.correctAnswer,
                isFlagged: false
            )
            details.append(detail)

            let correctIndex = question.options.firstIndex(of: question.correctAnswer) ?? 0
            let userIndex = question.options.firstIndex(of: userAnswerText ?? "")

            let item = QuizSummaryItem(
                questionText: question.text,
                userAnswerIndex: userIndex,
                correctAnswerIndex: correctIndex,
                allOptions: question.options,
                explanation: "The correct answer is \(question.correctAnswer).",
                isCorrect: isCorrect
            )
            summaryItems.append(item)
        }

        let elapsed = TimeInterval(60 - secondsRemaining)
        let finalResult = FinalQuizResult(
            finalScore: score,
            totalQuestions: questions.count,
            timeElapsed: elapsed,
            sourceName: currentTopic?.name ?? "Word Fill Game",
            details: details
        )

        return (finalResult, summaryItems)
    }

    // MARK: - Timer Logic
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
                let minutes = self.secondsRemaining / 60
                let seconds = self.secondsRemaining % 60
                self.timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
            } else {
                self.timer?.invalidate()
                self.showFinalResults()
            }
        }
    }

    // MARK: - Navigation Prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NavigateToResults" {
            if let destVC = segue.destination as? QuizResultsViewController,
               let (result, summaryItems) = sender as? (FinalQuizResult, [QuizSummaryItem]) {

                destVC.finalResult = result
                destVC.summaryData = summaryItems
                destVC.parentFolder = "Games"
                destVC.topicToSave = nil
            }
        }
    }
}
