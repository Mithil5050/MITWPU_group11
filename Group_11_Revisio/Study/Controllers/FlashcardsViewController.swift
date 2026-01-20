//
//  FlashcardsViewController.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 08/01/26.
//

import UIKit
import Foundation

// MARK: - 1. Flashcard Data Structure (Model)
struct Flashcards: Codable {
    let term: String
    let definition: String
}

// MARK: - 2. Delegation Protocol (Receives New Data)
protocol AddFlashcardsDelegate: AnyObject {
    func didCreateNewFlashcard(card: Flashcard)
}

// MARK: - 3. View Controller Implementation
class FlashcardsViewController: UIViewController, AddFlashcardsDelegate {

    // MARK: - View Controller Outlets (Connect these in your Storyboard)
    @IBOutlet weak var cardsView: UIView!
    @IBOutlet weak var cardsLabel: UILabel!
    @IBOutlet weak var previousButtonStudy: UIButton!
    @IBOutlet weak var nextButtonStudy: UIButton!
    @IBOutlet weak var counterLabel: UILabel!
    
    var currentTopic : Topic?
    var parentSubjectName: String?
    var isFromGenerationScreen: Bool = false
    // MARK: - State Management
    private var flashcards: [Flashcard] = []
    
    private var isTermDisplayed = true
    private var currentCardIndex = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCardViewAppearance()
        setupTapGesture()
        
       
        if let topicName = currentTopic?.name {
            self.title = topicName
        }
        
      
        if let savedContent = currentTopic?.largeContentBody {
            unpackFlashcards(from: savedContent)
        }
        
        updateCardContent(animated: false)
        updateCounterLabel()
    }
    // MARK: - Private Configuration Methods
    
    private func configureCardViewAppearance() {
        cardsView.layer.cornerRadius = 16
        cardsView.layer.masksToBounds = false
        cardsView.layer.shadowColor = UIColor.black.cgColor
        cardsView.layer.shadowOpacity = 0.1
        cardsView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardsView.layer.shadowRadius = 8
        cardsView.backgroundColor = UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0)


        
    }

    private func setupTapGesture() {
        cardsView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCardTap))
        cardsView.addGestureRecognizer(tapGesture)
    }
    private func updateCounterLabel() {
        guard !flashcards.isEmpty else {
            counterLabel?.text = "0/0"
            return
        }
        counterLabel?.text = "\(currentCardIndex + 1)/\(flashcards.count)"
        
        
        if isFromGenerationScreen && currentCardIndex == flashcards.count - 1 {
           
            nextButtonStudy.setTitle("Save", for: .normal)
            
            
            nextButtonStudy.backgroundColor = .secondarySystemFill
            nextButtonStudy.setTitleColor(.white, for: .normal)
        } else {
           
            nextButtonStudy.setTitle("Next", for: .normal)
            
            
            nextButtonStudy.backgroundColor = .secondarySystemFill
            nextButtonStudy.setTitleColor(.label, for: .normal)
        }
    }
    
    private func updateCardContent(animated: Bool = true) {

        guard !flashcards.isEmpty else {
            cardsLabel.text = "Tap Add to create a new flashcard."
            return
        }
        
        let card = flashcards[currentCardIndex]
        let newText = isTermDisplayed ? card.term : card.definition
        
        if animated {
            UIView.transition(with: cardsLabel, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.cardsLabel.text = newText
            }, completion: nil)
        } else {
            self.cardsLabel.text = newText
        }
    }
    
    // MARK: - User Interaction: Card Flip (Programmatic Handler)
    
    @objc func handleCardTap() {
        guard !flashcards.isEmpty else { return }
        
        let card = flashcards[currentCardIndex]
        let newText = isTermDisplayed ? card.definition : card.term
        
        let animationOptions: UIView.AnimationOptions = isTermDisplayed ? .transitionFlipFromRight : .transitionFlipFromLeft
        
        UIView.transition(with: cardsView, duration: 0.5, options: animationOptions, animations: {
            self.cardsLabel.text = newText
        }, completion: nil)
        
        isTermDisplayed.toggle()
    }
    
    // MARK: - User Interaction: Navigation (Storyboard Actions)
    
    @IBAction func nextCardButtonTapped(_ sender: UIButton) {
        if isFromGenerationScreen && currentCardIndex == flashcards.count - 1 {
                showSaveConfirmation()
                return
            }
            
            // Standard navigation logic
            guard !flashcards.isEmpty else { return }
            isTermDisplayed = true
            
            // Move to next card
            currentCardIndex = (currentCardIndex + 1) % flashcards.count
            
            updateCardContent()
            updateCounterLabel()    }

    @IBAction func previousCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        isTermDisplayed = true
        currentCardIndex = (currentCardIndex - 1 + flashcards.count) % flashcards.count
        updateCardContent()
        updateCounterLabel()
    }
    
    @IBAction func addFlashcardButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "addFlashcard", sender: self)
    }
    
    // MARK: - Segue Preparation (Injecting the Delegate)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addFlashcard" {
            if let navigationController = segue.destination as? UINavigationController,
               let destinationVC = navigationController.topViewController as? AddFlashcardsViewController {
                destinationVC.delegate = self
            } else if let destinationVC = segue.destination as? AddFlashcardsViewController {
                destinationVC.delegate = self
            }
        }
    }
    
    //  AddFlashcardDelegate Protocol Implementation
    
    // MARK: - AddFlashcardDelegate Protocol Implementation
    func didCreateNewFlashcard(card: Flashcard) {
        flashcards.append(card)
        
        let updatedText = flashcards.map { "\($0.term)|\($0.definition)" }.joined(separator: "\n")
        currentTopic?.largeContentBody = updatedText
        
        if let subject = parentSubjectName, let topicName = currentTopic?.name {
            // ADD "Flashcards" here too
            DataManager.shared.updateTopicContent(
                subject: subject,
                topicName: topicName,
                newText: updatedText,
                type: "Flashcards"
            )
        }
        
        currentCardIndex = flashcards.count - 1
        isTermDisplayed = true
        updateCardContent(animated: true)
        updateCounterLabel()
    }
    private func unpackFlashcards(from content: String) {
        let lines = content.components(separatedBy: "\n")
        var loadedCards: [Flashcard] = []
        
        for line in lines where !line.isEmpty {
            let parts = line.components(separatedBy: "|")
            if parts.count == 2 {
                loadedCards.append(Flashcard(term: parts[0], definition: parts[1]))
            }
        }
        
        if !loadedCards.isEmpty {
            self.flashcards = loadedCards
            self.currentCardIndex = 0
        }
    }
    private func showSaveConfirmation() {
        let alert = UIAlertController(title: "Save Flashcards", message: "These cards will be permanently added to your \(parentSubjectName ?? "Study") folder.", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Yes, Save", style: .default) { _ in
            self.persistGeneratedCards()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            self.navigationController?.popViewController(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    private func persistGeneratedCards() {
        guard let subject = parentSubjectName, let topic = currentTopic else { return }
        
        let finalContent = flashcards.map { "\($0.term)|\($0.definition)" }.joined(separator: "\n")
        
        let topicToSave = Topic(
            name: topic.name,
            lastAccessed: "Just now",
            materialType: "Flashcards",
            largeContentBody: finalContent,
            parentSubjectName: subject
        )
        
        DataManager.shared.addTopic(to: subject, topic: topicToSave)
        
        DataManager.shared.updateTopicContent(
            subject: subject,
            topicName: topic.name,
            newText: finalContent,
            type: "Flashcards"
        )
    }
}

