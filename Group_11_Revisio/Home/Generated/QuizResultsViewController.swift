import UIKit

class QuizResultsViewController: UIViewController {

    // MARK: - Data Properties
    var finalResult: FinalQuizResult?
    var topicToSave: Topic?
    var parentFolder: String?
    
    var summaryData: [QuizSummaryItem] = []
    
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
    }
    
    func setupUI() {
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
            retakeButton.isHidden = true // Typo 'truea' fixed here
            homeButton.setTitle("Back to Home", for: .normal)
        } else {
            retakeButton.isHidden = false
        }

        // 7. ✅ INTEGRATE XP SYSTEM
        // Using the 20 Base + 5 per correct answer formula
        Task {
            let baseXP = 20
            let performanceXP = result.finalScore * 5
            let totalEarned = baseXP + performanceXP
            
            // This triggers the sliding banner, haptic feedback, and cloud sync automatically
            await RevisioManager.shared.earnXP(amount: totalEarned, reason: "Quiz Mastery")
        }
    }

    // MARK: - Actions
    @IBAction func retakeButtonTapped(_ sender: UIButton) {
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
        // ✅ FIX: Do NOT save again here. Data was already saved in QuizSessionViewController.
        // We just need to go home.
        
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
        if indexPath.row == 1 {
            performSegue(withIdentifier: "ShowSummary", sender: self)
        }
    }
}
