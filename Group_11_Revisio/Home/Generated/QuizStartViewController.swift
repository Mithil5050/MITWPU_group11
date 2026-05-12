//
//  QuizStartViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 11/12/25.
//

import UIKit

class QuizStartViewController: UIViewController {

    var currentTopic: Topic?
    var parentSubject: String?
    var quizSourceName: String?
    var quizTimeLimit: Int = 15
    var quizQuestionCount: Int = 10
    
    @IBOutlet weak var quizTitleLabel: UILabel!
    @IBOutlet weak var rulesTextView: UITextView!
    @IBOutlet weak var beginButton: UIButton!
    @IBOutlet weak var saveAndCloseButton: UIButton!
    
    private var quizSubtitleLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = false
        configureUI()
        setupSubtitleLabel()
        designButtons()
    }
    
    func configureUI() {
        let displayName = quizSourceName ?? currentTopic?.name ?? parentSubject ?? "Quiz"
        let cleanName = displayName.replacingOccurrences(of: " Quiz", with: "")
        
        quizTitleLabel.text = "\(cleanName) Quiz"
        // Multi-line title so long names never truncate
        let navTitleLabel = UILabel()
        navTitleLabel.text = cleanName
        navTitleLabel.numberOfLines = 2
        navTitleLabel.textAlignment = .center
        navTitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        navTitleLabel.textColor = .label
        navTitleLabel.lineBreakMode = .byWordWrapping
        navTitleLabel.sizeToFit()
        navigationItem.titleView = navTitleLabel

        
        rulesTextView.text = generateRulesText()
    }
    
    func setupSubtitleLabel() {
        let subtitleLabel = UILabel()
        subtitleLabel.text = "\(quizQuestionCount) Questions | \(quizTimeLimit) minutes"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .left
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        quizTitleLabel.superview?.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: quizTitleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: quizTitleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: quizTitleLabel.trailingAnchor)
        ])
        
        self.quizSubtitleLabel = subtitleLabel
    }
    
    func designButtons() {
        beginButton.layer.cornerRadius = 10
        beginButton.clipsToBounds = true
        saveAndCloseButton.layer.cornerRadius = 10
        saveAndCloseButton.clipsToBounds = true
    }
    
    func generateRulesText() -> String {
        return """
        1. This quiz is not marked and will not affect any official course grades or records. Use it as a self-assessment tool.
        
        2. Questions: You will be answering \(quizQuestionCount) questions.
        
        3. Time Limit: You have \(quizTimeLimit) minutes to complete this session.
        
        4. For Multiple Choice questions, select the best single answer.
        
        5. Use the Next button at the bottom of the screen to move forward.
        
        6. Tap the Submit button on the final question to end the quiz.
        """
    }
    
    @IBAction func beginQuizPressed(_ sender: Any) {
        performSegue(withIdentifier: "BeginQuizAction", sender: currentTopic)
    }
    
    @IBAction func saveQuizPressed(_ sender: Any) {
        guard let topic = currentTopic, let subject = parentSubject else { return }
        
        let quizToSave = Topic(
            name: topic.name,
            lastAccessed: "Just now",
            materialType: "Quiz",
            parentSubjectName: subject,
            quizQuestions: topic.quizQuestions,
            largeContentBody: topic.largeContentBody,
            notesContent: topic.notesContent,
            cheatsheetContent: topic.cheatsheetContent
        )
        
        DataManager.shared.addTopic(to: subject, topic: quizToSave)
        showSaveAlert(folderName: subject)
    }
    
    func showSaveAlert(folderName: String) {
        let alert = UIAlertController(title: "Saved!", message: "Quiz has been successfully saved to '\(folderName)'.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if let nav = self?.navigationController {
                nav.popToRootViewController(animated: true)
            } else {
                self?.dismiss(animated: true)
            }
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BeginQuizAction" {
            let nameToPass = self.quizSourceName ?? self.currentTopic?.name ?? "Quiz"
            
            if let newQuizVC = segue.destination as? QuizViewController {
                newQuizVC.quizTopic = self.currentTopic
                newQuizVC.parentSubjectName = self.parentSubject
                newQuizVC.selectedSourceName = nameToPass
                newQuizVC.timeLimitInMinutes = self.quizTimeLimit
                return
            }
            
            if let oldQuizVC = segue.destination as? QuizSessionViewController {
                oldQuizVC.currentTopic = self.currentTopic
                oldQuizVC.parentSubject = self.parentSubject
                oldQuizVC.sourceName = nameToPass
                return
            }
        }
    }
}
