//
//  QuizResultsViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 18/01/26.
//

import UIKit

class QuizResultsViewController: UIViewController {

    // MARK: - Data Properties
    var finalResult: FinalQuizResult?
    var topicToSave: Topic?
    var parentFolder: String?
    
    // This array receives data from the Session and passes it to Summary
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
        guard let result = finalResult else { return }
        
        // 1. Set Score Text
        scoreLabel.text = "You Scored \(result.finalScore) out of \(result.totalQuestions)."
        
        // 2. Handle Text & Image based on Score
        let percentage = Double(result.finalScore) / Double(result.totalQuestions)
        
        if percentage < 0.5 {
            headerLabel.text = "Better luck next time!"
            resultImageView.image = UIImage(named: "BadMarks")
        } else {
            headerLabel.text = "Congratulations!"
            resultImageView.image = UIImage(named: "GoodMarks")
        }
        
        // 3. Configure TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        
        // 4. Style Buttons
        retakeButton.layer.cornerRadius = 14
        homeButton.layer.cornerRadius = 14
        
        // 5. Game Mode Check (Hide Retake for Games/WordFill)
        if topicToSave == nil {
            retakeButton.isHidden = true
            homeButton.setTitle("Back to Home", for: .normal)
        } else {
            retakeButton.isHidden = false
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
        if let topic = topicToSave, let subject = parentFolder {
            // Save logic for normal quizzes
            let updatedTopic = Topic(name: topic.name, lastAccessed: "Just now", materialType: "Quiz", largeContentBody: topic.largeContentBody, parentSubjectName: subject, notesContent: topic.notesContent, cheatsheetContent: topic.cheatsheetContent)
            DataManager.shared.addTopic(to: subject, topic: updatedTopic)
            
            let alert = UIAlertController(title: "Saved!", message: "Quiz saved to '\(parentFolder ?? "Study")'.", preferredStyle: .alert)
            
            // ✅ MODIFIED: Navigate to Home Screen upon tapping OK
            let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                // Check if we are in a navigation stack
                if let nav = self.navigationController {
                    // Pop to the root view controller (Home Screen)
                    nav.popToRootViewController(animated: true)
                } else {
                    // If presented modally, dismiss it
                    self.dismiss(animated: true, completion: nil)
                }
            }
            alert.addAction(okAction)
            present(alert, animated: true)
            
        } else {
            // Direct exit for Games (Word Fill) - already behaves correctly but ensuring consistency
            if let nav = self.navigationController {
                nav.popToRootViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
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
