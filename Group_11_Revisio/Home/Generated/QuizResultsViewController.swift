import UIKit

class QuizResultsViewController: UIViewController {

    // MARK: - Data Properties
    var finalResult: FinalQuizResult?
    var topicToSave: Topic?
    var parentFolder: String?
    
    var summaryData: [QuizSummaryItem] = []
    
    // MARK: - Flashcard Properties
    var isFlashcardMode: Bool = false
    var knownCount: Int = 0
    var unknownCount: Int = 0
    var weakestTerm: String?
    var onChallengeMode: (() -> Void)?
    var onSaveAndExit: (() -> Void)?
    
    // MARK: - Outlets
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // ✅ Disable swipe-to-go-back so they can't bypass the warning
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        // ✅ Override the default back button with our custom warning
        let backAction = UIAction { [weak self] _ in
            self?.showExitWarning()
        }
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), primaryAction: backAction)
        navigationItem.leftBarButtonItem = backButton
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // ✅ Re-enable swipe-to-go-back for the rest of the app
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func setupUI() {
        if isFlashcardMode {
            setupForFlashcards()
            return
        }
        
        // 1. Safety check for the result data
        guard let result = finalResult else { return }
        
        // 2. Update Score Text
        scoreLabel.text = "You Scored \(result.finalScore) out of \(result.totalQuestions)."
        
        // 3. Determine performance (Percentage) and update Header/Image
        let percentage = Double(result.finalScore) / Double(result.totalQuestions)
        if percentage < 0.5 {
            headerLabel.text = "Better luck next time!"
            resultImageView.image = UIImage(named: "BadMarks")
        } else {
            headerLabel.text = "Congratulations!"
            resultImageView.image = UIImage(named: "GoodMarks")
        }
        
        // 4. Configure TableView for Time Taken and Summary
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        
        // 5. Style the Action Buttons
        retakeButton.layer.cornerRadius = 14
        homeButton.layer.cornerRadius = 14
        
        // 6. Handle Navigation Logic (Hide Retake if it's a quick quiz without a saved topic)
        if topicToSave == nil {
            retakeButton.isHidden = true
            homeButton.setTitle("Back to Home", for: .normal)
        } else {
            retakeButton.isHidden = false
        }

        // 7. ✅ INTEGRATE XP SYSTEM
        Task {
            let baseXP = 20
            let performanceXP = result.finalScore * 5
            let totalEarned = baseXP + performanceXP
            
            // This triggers the sliding banner, haptic feedback, and cloud sync automatically
            await RevisioManager.shared.earnXP(amount: totalEarned, reason: "Quiz Mastery")
            let quizMinutes = Double(result.timeElapsed) / 60.0
            ProgressDataManager.shared.logSession(minutes: max(quizMinutes, 1.0), category: "Study")
        }
    }
    
    private func setupForFlashcards() {
        scoreLabel.text = "You mastered all \(knownCount) cards!"
        
        let percentage = Double(knownCount) / Double(max(knownCount, 1))
        if percentage < 0.5 {
            headerLabel.text = "Result Screen"
            resultImageView.image = UIImage(named: "BadMarks")
        } else {
            headerLabel.text = "Result Screen"
            resultImageView.image = UIImage(named: "GoodMarks")
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none // Cleaner look for flashcards
        
        retakeButton.setTitle("Challenge Mode", for: .normal)
        homeButton.setTitle("Save & Exit", for: .normal)
        
        retakeButton.layer.cornerRadius = 14
        homeButton.layer.cornerRadius = 14
        
        retakeButton.isHidden = false
        homeButton.isHidden = false
    }

    // ✅ Exit Warning Pop-up
    private func showExitWarning() {
        if isFlashcardMode {
            let alert = UIAlertController(title: "Quit Session?", message: "Your progress will be saved automatically. Exit?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Exit", style: .default) { [weak self] _ in
                self?.dismiss(animated: true) { self?.onSaveAndExit?() }
            })
            present(alert, animated: true)
            return
        }
        let alert = UIAlertController(
            title: "Quit Quiz?",
            message: "Your progress for this attempt will be lost. Are you sure you want to Quit?",
            preferredStyle: .alert
        )
        
        let resumeAction = UIAlertAction(title: "Resume", style: .cancel, handler: nil)
        
        let quitAction = UIAlertAction(title: "Quit", style: .destructive) { [weak self] _ in
            // Navigate to Home
            if let nav = self?.navigationController {
                nav.popToRootViewController(animated: true)
            } else {
                self?.dismiss(animated: true, completion: nil)
            }
        }
        
        alert.addAction(resumeAction)
        alert.addAction(quitAction)
        
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Actions
    @IBAction func retakeButtonTapped(_ sender: UIButton) {
        if isFlashcardMode {
            dismiss(animated: true) { self.onChallengeMode?() }
            return
        }
        
        if let nav = navigationController, let sessionVC = nav.viewControllers.first(where: { $0 is QuizSessionViewController }) as? QuizSessionViewController {
            sessionVC.questionIndex = 0
            sessionVC.initiateTimer()
            for i in 0..<sessionVC.sessionQuestions.count {
                sessionVC.sessionQuestions[i].userAnswerIndex = nil
                sessionVC.sessionQuestions[i].isFlagged = false
            }
            sessionVC.renderQuestion()
            nav.popToViewController(sessionVC, animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func homeButtonTapped(_ sender: UIButton) {
        if isFlashcardMode {
            dismiss(animated: true) { self.onSaveAndExit?() }
            return
        }
        
        // Just Navigate Home
        if let nav = self.navigationController {
            nav.popToRootViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSummary" {
            if let destVC = segue.destination as? SummaryViewController {
                destVC.summaryList = self.summaryData
            }
        }
    }
}

// MARK: - TableView
extension QuizResultsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFlashcardMode { return 1 }
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isFlashcardMode {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "FlashcardResultCell")
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            
            // Container View
            let container = UIView()
            container.backgroundColor = UIColor(red: 0.13, green: 0.15, blue: 0.24, alpha: 1.0) // App Indigo
            container.layer.cornerRadius = 16
            container.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(container)
            
            NSLayoutConstraint.activate([
                container.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 24),
                container.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -24),
                container.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
            
            // Icon
            let isPerfect = weakestTerm == nil
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
            let iconName = isPerfect ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
            let iconColor = isPerfect ? UIColor.systemGreen : UIColor.systemOrange
            
            let iconView = UIImageView(image: UIImage(systemName: iconName, withConfiguration: iconConfig))
            iconView.tintColor = iconColor
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(iconView)
            
            // Title
            let titleLabel = UILabel()
            titleLabel.text = isPerfect ? "PERFECT SCORE" : "NEEDS ATTENTION"
            titleLabel.textColor = iconColor
            titleLabel.font = .systemFont(ofSize: 14, weight: .heavy)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(titleLabel)
            
            // Detail
            let detailLabel = UILabel()
            detailLabel.text = isPerfect ? "You've mastered every card in this deck!" : weakestTerm!
            detailLabel.textColor = .white
            detailLabel.font = .systemFont(ofSize: 18, weight: .semibold)
            detailLabel.numberOfLines = 0
            detailLabel.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(detailLabel)
            
            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
                iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
                iconView.widthAnchor.constraint(equalToConstant: 32),
                iconView.heightAnchor.constraint(equalToConstant: 32),
                
                titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
                titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
                
                detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
                detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
                detailLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
            ])
            
            return cell
        }
        
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "ResultCell")
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Time Taken"
            let time = finalResult?.timeElapsed ?? 0
            cell.detailTextLabel?.text = String(format: "%02d:%02d", Int(time)/60, Int(time)%60)
            cell.selectionStyle = .none
        } else {
            cell.textLabel?.text = "See Summary"
            cell.detailTextLabel?.text = ""
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isFlashcardMode { return }
        
        if indexPath.row == 1 {
            performSegue(withIdentifier: "ShowSummary", sender: self)
        }
    }
}
