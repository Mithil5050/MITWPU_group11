import UIKit

class ResultsViewController: UIViewController {

    // MARK: - Properties
    var finalResult: FinalQuizResult?
    var topicToSave: Topic?
    var parentFolder: String?
    
    
    var summaryData: [QuizSummaryItem] = []
    
    // MARK: - Outlets
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var detailTableView: UITableView!
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var resultImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backAction = UIAction { [weak self] _ in
            let alert = UIAlertController(
                title: "Unsaved Progress",
                message: "Are you sure you want to leave? Your quiz results will not be saved.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Stay", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
                if let nav = self?.navigationController {
                    for vc in nav.viewControllers {
                        if vc is SubjectViewController {
                            nav.popToViewController(vc, animated: true)
                            return
                        }
                    }
                    nav.popToRootViewController(animated: true)
                }
            })
            
            self?.present(alert, animated: true)
        }
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func setupUI() {
        guard let result = finalResult else { return }
        
        scoreLabel.text = "You Scored \(result.finalScore) out of \(result.totalQuestions)."
        
        let percentage = Double(result.finalScore) / Double(result.totalQuestions)
        
        if percentage < 0.5 {
            headerLabel.text = "Better luck next time!"
            resultImageView.image = UIImage(named: "BadMarks")
        } else {
            headerLabel.text = "Congratulations!"
            resultImageView.image = UIImage(named: "GoodMarks")
        }
        
        detailTableView.delegate = self
        detailTableView.dataSource = self
        detailTableView.tableFooterView = UIView()
        detailTableView.backgroundColor = .clear
        detailTableView.isScrollEnabled = false
        
        retakeButton.layer.cornerRadius = 14
        saveButton.layer.cornerRadius = 14
    }
  
    // MARK: - Actions
    @IBAction func retakeButtonTapped(_ sender: Any) {
        // Find your Study Tab's QuizViewController in the navigation stack
        if let nav = navigationController,
           let quizVC = nav.viewControllers.first(where: { $0 is QuizViewController }) as? QuizViewController {
            
            // Reset question states
            quizVC.currentQuestionIndex = 0
            quizVC.score = 0
            for i in 0..<quizVC.allQuestions.count {
                quizVC.allQuestions[i].userAnswerIndex = nil
            }
            
            quizVC.displayQuestion()
            quizVC.startTimer()
            nav.popToViewController(quizVC, animated: true)
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        guard let result = finalResult,
                  var topic = topicToSave,
                  let folderName = parentFolder else { return }
            
           
            let packedData = summaryData.map { item in
                let answers = item.allOptions.joined(separator: "|")
                return "\(item.questionText)|\(answers)|\(item.correctAnswerIndex)|\(item.explanation)"
            }.joined(separator: "\n")
            
           
            topic.largeContentBody = packedData
            topic.lastAccessed = "Just now"
            
            
            DataManager.shared.addTopic(to: folderName, topic: topic)
            
            
            let alert = UIAlertController(
                title: "Saved!",
                message: "Quiz saved to '\(folderName)'.",
                preferredStyle: .alert
            )
            
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            if let navigationController = self.navigationController {
                let viewControllers = navigationController.viewControllers
                
                for vc in viewControllers {
                    if vc is SubjectViewController {
                        navigationController.popToViewController(vc, animated: true)
                        return
                    }
                }
                
                navigationController.popViewController(animated: true)
            }
        })
            present(alert, animated: true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Match the identifier to your Storyboard Segue
        if segue.identifier == "ShowReviewDetail" {
            if let destVC = segue.destination as? ReviewDetailViewController {
                destVC.summaryList = self.summaryData
            }
        }
    }
}

// MARK: - TableView Handling
extension ResultsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "DetailCell")
        
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .label
        cell.detailTextLabel?.textColor = .secondaryLabel
        
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
            performSegue(withIdentifier: "ShowReviewDetail", sender: nil)
        }
    }
}
