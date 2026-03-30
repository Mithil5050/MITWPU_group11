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
        let total = knownCount + unknownCount
        scoreLabel.text = "You mastered \(knownCount) out of \(total)."
        
        let percentage = total > 0 ? Double(knownCount) / Double(total) : 0
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 2 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "ResultCell")
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray
        
        if isFlashcardMode {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Known"
                cell.detailTextLabel?.text = "\(knownCount)"
                cell.detailTextLabel?.textColor = .white
            } else {
                cell.textLabel?.text = "Not Known"
                cell.detailTextLabel?.text = "\(unknownCount)"
                cell.detailTextLabel?.textColor = .white
            }
            cell.selectionStyle = .none
            cell.accessoryType = .none
            return cell
        }
        
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
