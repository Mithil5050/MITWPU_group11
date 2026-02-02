import UIKit

class QuizHistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var quizTopic: Topic?
    var parentSubject: String?
    var summaryData: [QuizSummaryItem] = []
    var latestScore: String = "—"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let subject = parentSubject, let currentName = quizTopic?.name {
            if let updatedTopic = DataManager.shared.getTopic(subjectName: subject, topicName: currentName) {
                self.quizTopic = updatedTopic
            }
        }
        
        unpackSummaryData()
        tableView.reloadData()
        tableView.tableHeaderView = createModernHeroHeader()
    }
    
    func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
    }
    func unpackSummaryData() {
        guard let topic = quizTopic else { return }
        
        // 1. Refresh score text for the header
        if topic.lastAccessed.contains("/") {
            self.latestScore = topic.lastAccessed.replacingOccurrences(of: "Score: ", with: "")
        }

        // 2. Get the body text: Try latest attempt first, then fallback to original content
        let body = topic.safeAttempts.last?.summaryData ?? topic.largeContentBody ?? ""
        
        guard !body.isEmpty else {
            self.summaryData = []
            return
        }
        
        let rows = body.components(separatedBy: "\n")
        self.summaryData = rows.compactMap { row -> QuizSummaryItem? in
            let parts = row.components(separatedBy: "|")
            
            // Safety: We need at least Question|O1|O2|O3|O4|CorrectIdx
            guard parts.count >= 6 else { return nil }
            
            let correctIdx = Int(parts[5]) ?? 0
            
            // NEW LOGIC: In a saved attempt, the UserAnswerIndex is the 8th part (index 7)
            // Format: Q|O1|O2|O3|O4|Correct|Hint|UserIdx
            let userIdx = parts.count >= 8 ? (Int(parts[7]) ?? -1) : -1
            
            return QuizSummaryItem(
                questionText: parts[0],
                userAnswerIndex: userIdx == -1 ? nil : userIdx,
                correctAnswerIndex: correctIdx,
                allOptions: [parts[1], parts[2], parts[3], parts[4]],
                explanation: parts.count > 6 ? parts[6] : "No explanation available.",
                isCorrect: (userIdx != -1 && userIdx == correctIdx)
            )
        }
    }
    func createModernHeroHeader() -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 260))
        
        let titleLabel = UILabel()
        titleLabel.text = quizTopic?.name ?? "Quiz"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.frame = CGRect(x: 20, y: 10, width: view.frame.width - 40, height: 40)
        headerView.addSubview(titleLabel)

        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 24
        card.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(card)
        
        let scoreLabel = UILabel()
        scoreLabel.text = latestScore
        scoreLabel.font = .systemFont(ofSize: 54, weight: .black)
        scoreLabel.textColor = summaryData.isEmpty ? .systemGray4 : .label
        scoreLabel.textAlignment = .center
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(scoreLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = summaryData.isEmpty ? "NO PREVIOUS ATTEMPT" : "LATEST SCORE"
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .heavy)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            card.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            card.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10),
            scoreLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: -10),
            scoreLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 2),
            subtitleLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor)
        ])
        
        return headerView
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return quizTopic?.safeAttempts.count ?? 0
        }
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "HistoryCell")
            let history = quizTopic?.safeAttempts.reversed() ?? []
            let attempt = Array(history)[indexPath.row]
            
            cell.textLabel?.text = attempt.dateString
            cell.detailTextLabel?.text = "\(attempt.score)/\(attempt.totalQuestions)"
            cell.textLabel?.font = .systemFont(ofSize: 15)
            cell.detailTextLabel?.font = .systemFont(ofSize: 15, weight: .bold)
            cell.backgroundColor = .secondarySystemGroupedBackground
            return cell
        }

        let cell = UITableViewCell(style: .default, reuseIdentifier: "ActionCell")
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.textLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "Review Latest Summary"
            cell.textLabel?.textColor = .systemBlue
            let hasHistory = !summaryData.isEmpty
            cell.alpha = hasHistory ? 1.0 : 0.5
            cell.isUserInteractionEnabled = hasHistory
        } else {
            cell.textLabel?.text = "Retake Quiz"
            cell.textLabel?.textColor = .label
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2 && !(quizTopic?.safeAttempts.isEmpty ?? true) {
            return "PAST ATTEMPTS"
        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            performSegue(withIdentifier: "ShowReviewDetailFromHistory", sender: nil)
        } else if indexPath.section == 1 {
            performSegue(withIdentifier: "ShowInstructionScreen", sender: quizTopic)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowReviewDetailFromHistory",
           let destVC = segue.destination as? ReviewDetailViewController {
            destVC.summaryList = self.summaryData
        } else if segue.identifier == "ShowInstructionScreen",
                  let instructionVC = segue.destination as? InstructionViewController {
            instructionVC.quizTopic = self.quizTopic
            instructionVC.parentSubjectName = self.parentSubject
        }
    }
}
