//
//  GenerateHomeViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 15/12/25.
//  Updated for Gen AI with Fail-Safe Data Handling
//

import UIKit

class GenerateHomeViewController: UIViewController {

    // MARK: - Data Properties
    var selectedMaterialType: GenerationType = .none
    var inputSourceData: [Any]? // Data source passed from previous screen
    var contextSubjectTitle: String? // Contextual name (e.g., "Calculus")

    // MARK: - IBOutlets
    @IBOutlet weak var startCreationButton: UIButton!

    // Settings container views
    @IBOutlet weak var quizConfigurationView: UIView!
    @IBOutlet weak var flashcardConfigurationView: UIView!
    @IBOutlet weak var defaultConfigurationPlaceholder: UIView!

    // Top Tab Buttons
    @IBOutlet weak var quizTabButton: UIButton!
    @IBOutlet weak var flashcardsTabButton: UIButton!
    @IBOutlet weak var notesTabButton: UIButton!
    @IBOutlet weak var cheatsheetTabButton: UIButton!

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup initial state: Select Quiz by default
        displayConfigurationView(quizConfigurationView)
        styleSelectedTabButton(selectedButton: quizTabButton)
        updateStartCreationButton(for: .quiz)
    }

    // MARK: - Configuration Methods
    private func displayConfigurationView(_ viewToShow: UIView) {
        let allConfigViews: [UIView?] = [
            quizConfigurationView,
            flashcardConfigurationView,
            defaultConfigurationPlaceholder
        ]
        allConfigViews.forEach { $0?.isHidden = true }
        viewToShow.isHidden = false
    }

    private func updateStartCreationButton(for type: GenerationType) {
        self.selectedMaterialType = type
        
        let title = (type == .none) ? "Start Creation" : "Create \(type.description)"
        let isEnabled = (type != .none)
        
        startCreationButton.setTitle(title, for: .normal)
        startCreationButton.isEnabled = isEnabled
        startCreationButton.alpha = isEnabled ? 1.0 : 0.5
    }

    private func styleSelectedTabButton(selectedButton: UIButton) {
        let allButtons = [quizTabButton, flashcardsTabButton, notesTabButton, cheatsheetTabButton]
        
        // Modern Gray Aesthetic Colors
        let unselectedBackground = UIColor.systemGray6
        let selectedBackground = UIColor.systemGray4
        let unselectedTitleColor = UIColor.secondaryLabel
        let selectedTitleColor = UIColor.label
        
        for button in allButtons {
            guard let btn = button else { continue }
            let isSelected = (btn === selectedButton)
            
            btn.backgroundColor = isSelected ? selectedBackground : unselectedBackground
            btn.setTitleColor(isSelected ? selectedTitleColor : unselectedTitleColor, for: .normal)
            btn.tintColor = isSelected ? selectedTitleColor : unselectedTitleColor
            btn.layer.cornerRadius = 12
        }
    }

    // MARK: - Actions (Tab Taps)
    @IBAction func quizTabButtonTapped(_ sender: UIButton) {
        displayConfigurationView(quizConfigurationView)
        styleSelectedTabButton(selectedButton: sender)
        updateStartCreationButton(for: .quiz)
    }

    @IBAction func flashcardsTabButtonTapped(_ sender: UIButton) {
        displayConfigurationView(flashcardConfigurationView)
        styleSelectedTabButton(selectedButton: sender)
        updateStartCreationButton(for: .flashcards)
    }

    @IBAction func notesTabButtonTapped(_ sender: UIButton) {
        displayConfigurationView(defaultConfigurationPlaceholder)
        styleSelectedTabButton(selectedButton: sender)
        updateStartCreationButton(for: .notes)
    }

    @IBAction func cheatsheetTabButtonTapped(_ sender: UIButton) {
        displayConfigurationView(defaultConfigurationPlaceholder)
        styleSelectedTabButton(selectedButton: sender)
        updateStartCreationButton(for: .cheatsheet)
    }

    // MARK: - Main Action (Start Creation with Gen AI)
    @IBAction func startCreationButtonTapped(_ sender: UIButton) {
        
        // 1. Check if we have source data passed from the previous screen
        if let sourceItem = inputSourceData?.first {
            // CASE A: We have data! Proceed automatically.
            let topicName = extractName(from: sourceItem)
            startAIGeneration(topic: topicName)
            
        } else {
            // CASE B: No data found (Fix for "Error: No source item available")
            // Show an alert asking the user what they want to study
            showManualTopicInput()
        }
    }

    // MARK: - Helper Methods
    
    private func extractName(from item: Any) -> String {
        if let content = item as? StudyContent { return content.filename }
        if let topic = item as? Topic { return topic.name }
        if let str = item as? String { return str } // Handles strings from SelectMaterialViewController
        return "General Knowledge"
    }

    private func showManualTopicInput() {
        let alert = UIAlertController(title: "Enter Topic", message: "What topic should the AI generate content for?", preferredStyle: .alert)
        
        alert.addTextField { tf in
            tf.placeholder = "e.g. Calculus, Swift, Biology..."
        }
        
        let createAction = UIAlertAction(title: "Generate", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            self?.startAIGeneration(topic: text)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(createAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    private func startAIGeneration(topic: String) {
        print("🚀 Starting AI Generation for: \(topic)")
        
        // 1. UI Loading State
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = self.view.center
        spinner.color = .systemBlue
        spinner.startAnimating()
        self.view.addSubview(spinner)
        self.view.isUserInteractionEnabled = false
        
        // 2. Call AI Service
        if selectedMaterialType == .quiz {
            APIService.shared.generateQuiz(for: topic) { [weak self] questions in
                DispatchQueue.main.async {
                    self?.finishLoading(spinner: spinner)
                    guard let questions = questions, !questions.isEmpty else {
                        self?.showErrorAlert()
                        return
                    }
                    self?.handleQuizSuccess(topicName: topic, questions: questions)
                }
            }
        } else if selectedMaterialType == .flashcards {
            APIService.shared.generateFlashcards(for: topic) { [weak self] cards in
                DispatchQueue.main.async {
                    self?.finishLoading(spinner: spinner)
                    guard let cards = cards, !cards.isEmpty else {
                        self?.showErrorAlert()
                        return
                    }
                    self?.handleFlashcardSuccess(topicName: topic, cards: cards)
                }
            }
        } else {
            // Fallback for types not yet supported
            finishLoading(spinner: spinner)
            let alert = UIAlertController(title: "Coming Soon", message: "AI generation for \(selectedMaterialType.description) is under construction.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    // MARK: - Completion Handlers
    
    private func finishLoading(spinner: UIActivityIndicatorView) {
        spinner.stopAnimating()
        spinner.removeFromSuperview()
        self.view.isUserInteractionEnabled = true
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(title: "Generation Failed", message: "The AI could not generate content. Please check your internet connection.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func handleQuizSuccess(topicName: String, questions: [QuizQuestion]) {
        // 1. Format: Question|Ans1|Ans2|Ans3|Ans4|CorrectIndex|Hint
        let contentString = questions.map { q in
            "\(q.questionText)|\(q.answers.joined(separator: "|"))|\(q.correctAnswerIndex)|\(q.hint)"
        }.joined(separator: "\n")
        
        // 2. Create Topic
        let newTopic = Topic(
            name: "\(topicName) Quiz",
            lastAccessed: "Just now",
            materialType: "Quiz",
            largeContentBody: contentString,
            parentSubjectName: self.contextSubjectTitle
        )
        
        // 3. Save
        DataManager.shared.addTopic(to: self.contextSubjectTitle ?? "General Study", topic: newTopic)
        
        // 4. Navigate
        let payload = (topic: newTopic, sourceName: newTopic.name)
        performSegue(withIdentifier: "HomeToQuizInstruction", sender: payload)
    }
    
    private func handleFlashcardSuccess(topicName: String, cards: [Flashcard]) {
        // 1. Format: Term|Definition
        let contentString = cards.map { c in
            "\(c.term)|\(c.definition)"
        }.joined(separator: "\n")
        
        // 2. Create Topic
        let newTopic = Topic(
            name: "\(topicName) Flashcards",
            lastAccessed: "Just now",
            materialType: "Flashcards",
            largeContentBody: contentString,
            parentSubjectName: self.contextSubjectTitle
        )
        
        // 3. Save
        DataManager.shared.addTopic(to: self.contextSubjectTitle ?? "General Study", topic: newTopic)
        
        // 4. Navigate
        performSegue(withIdentifier: "HomeToFlashcardView", sender: newTopic)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Quiz Segue
        if segue.identifier == "HomeToQuizInstruction" {
            if let dest = segue.destination as? InstructionViewController,
               let data = sender as? (topic: Topic, sourceName: String) {
                
                dest.quizTopic = data.topic
                dest.sourceNameForQuiz = data.sourceName
                dest.parentSubjectName = self.contextSubjectTitle
            }
        }
        
        // Flashcard Segue
        else if segue.identifier == "HomeToFlashcardView" {
            if let dest = segue.destination as? FlashcardsViewController,
               let topic = sender as? Topic {
                
                dest.currentTopic = topic
                dest.parentSubjectName = self.contextSubjectTitle
            }
        }
    }
}
