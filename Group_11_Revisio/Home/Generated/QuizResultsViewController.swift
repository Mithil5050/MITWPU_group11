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
    
    // ✅ NEW: This array receives data from the Session and passes it to Summary
    var summaryData: [QuizSummaryItem] = []
    
    // MARK: - Outlets
    @IBOutlet weak var scoreLabel: UILabel!
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
        scoreLabel.text = "You Scored \(result.finalScore) out of \(result.totalQuestions)."
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        
        retakeButton.layer.cornerRadius = 14
        homeButton.layer.cornerRadius = 14
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
             let updatedTopic = Topic(name: topic.name, lastAccessed: "Just now", materialType: "Quiz", largeContentBody: topic.largeContentBody, parentSubjectName: subject, notesContent: topic.notesContent, cheatsheetContent: topic.cheatsheetContent)
            DataManager.shared.addTopic(to: subject, topic: updatedTopic)
        }
        
        let alert = UIAlertController(title: "Saved!", message: "Quiz saved to '\(parentFolder ?? "Study")'.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // ✅ CRITICAL FIX: Actually pass the data here
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
            // This triggers the prepare method above
            performSegue(withIdentifier: "ShowSummary", sender: self)
        }
    }
}
