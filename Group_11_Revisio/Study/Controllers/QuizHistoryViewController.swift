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
        
        // Sets the title in the system Navigation Bar
        self.title = quizTopic?.name ?? "Quiz History"
        
        if let subject = parentSubject, let currentName = quizTopic?.name {
            if let updatedTopic = DataManager.shared.getTopic(subjectName: subject, topicName: currentName) {
                self.quizTopic = updatedTopic
            }
        }
        
        unpackSummaryData()
        tableView.reloadData()
        
        // Pushes the score card to the top
        tableView.tableHeaderView = createModernHeroHeader()
    }
    
    func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        
        // Removes top gap on iOS 15+
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    func createModernHeroHeader() -> UIView {
        // Minimal height to move content up
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 150))

        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 24
        card.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(card)
        
        let scoreLabel = UILabel()
        scoreLabel.text = latestScore
        
        // Native Dynamic Type for large score
        let scoreFont = UIFont.systemFont(ofSize: 54, weight: .black)
        scoreLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: scoreFont)
        scoreLabel.adjustsFontForContentSizeCategory = true
        
        scoreLabel.textColor = summaryData.isEmpty ? .systemGray4 : .label
        scoreLabel.textAlignment = .center
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(scoreLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = summaryData.isEmpty ? "NO PREVIOUS ATTEMPT" : "LATEST SCORE"
        
        // Native caption style
        let subtitleFont = UIFont.systemFont(ofSize: 12, weight: .heavy)
        subtitleLabel.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: subtitleFont)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 5),
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
            
            // Native body scaling
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textLabel?.adjustsFontForContentSizeCategory = true
            
            let detailFont = UIFont.systemFont(ofSize: 15, weight: .bold)
            cell.detailTextLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: detailFont)
            cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
            cell.detailTextLabel?.textColor = .label
            
            cell.backgroundColor = .secondarySystemGroupedBackground
            return cell
        }

        let cell = UITableViewCell(style: .default, reuseIdentifier: "ActionCell")
        cell.backgroundColor = .secondarySystemGroupedBackground
        
        let actionFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        cell.textLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: actionFont)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        
        cell.accessoryType = .disclosureIndicator
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "Review Latest Summary"
            cell.textLabel?.textColor = .systemBlue
            let hasHistory = !summaryData.isEmpty
            cell.alpha = hasHistory ? 1.0 : 0.5
            cell.isUserInteractionEnabled = hasHistory
        } else {
            cell.textLabel?.text = "Retake Quiz"
            cell.textLabel?.textColor = .label
        }
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 2 && !(quizTopic?.safeAttempts.isEmpty ?? true) {
            let headerView = UIView()
            let label = UILabel()
            label.text = "PAST ATTEMPTS"
            
            let headerFont = UIFont.systemFont(ofSize: 13, weight: .heavy)
            label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: headerFont)
            label.adjustsFontForContentSizeCategory = true
            
            label.textColor = .secondaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 24),
                label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
            ])
            return headerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 2 ? 40 : 0
    }
    
    func unpackSummaryData() {
        guard let topic = quizTopic else { return }
        if topic.lastAccessed.contains("/") {
            self.latestScore = topic.lastAccessed.replacingOccurrences(of: "Score: ", with: "")
        }
        let body = topic.safeAttempts.last?.summaryData ?? topic.largeContentBody ?? ""
        guard !body.isEmpty else { return }
        
        let rows = body.components(separatedBy: "\n")
        self.summaryData = rows.compactMap { row -> QuizSummaryItem? in
            let parts = row.components(separatedBy: "|")
            guard parts.count >= 6 else { return nil }
            
            let correctIdx = Int(parts[5]) ?? 0
            let userIdx = parts.count >= 8 ? (Int(parts[7]) ?? -1) : -1
            
            return QuizSummaryItem(
                questionText: parts[0],
                userAnswerIndex: userIdx == -1 ? nil : userIdx,
                correctAnswerIndex: correctIdx,
                allOptions: [parts[1], parts[2], parts[3], parts[4]],
                explanation: parts.count > 6 ? parts[6] : "No hint",
                isCorrect: (userIdx != -1 && userIdx == correctIdx)
            )
        }
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
