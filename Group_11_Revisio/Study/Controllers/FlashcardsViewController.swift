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
    
    var currentTopic : Topic?
    var parentSubjectName: String?
    // MARK: - State Management
    private var flashcards: [Flashcard] = []
    
    private var isTermDisplayed = true
    private var currentCardIndex = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCardViewAppearance()
        setupTapGesture()
        
        // CHANGE 1: Set the Title to match the folder (e.g., "Partial Derivatives")
        if let topicName = currentTopic?.name {
            self.title = topicName
        }
        
        // CHANGE 2: Load the specific cards from the JSON body
        if let savedContent = currentTopic?.largeContentBody {
            unpackFlashcards(from: savedContent)
        }
        
        updateCardContent(animated: false)
    }
    // MARK: - Private Configuration Methods
    
    private func configureCardViewAppearance() {
        cardsView.layer.cornerRadius = 16
        cardsView.layer.masksToBounds = false
        cardsView.layer.shadowColor = UIColor.black.cgColor
        cardsView.layer.shadowOpacity = 0.1
        cardsView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardsView.layer.shadowRadius = 8
    }

    private func setupTapGesture() {
        cardsView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCardTap))
        cardsView.addGestureRecognizer(tapGesture)
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
        guard !flashcards.isEmpty else { return }
        isTermDisplayed = true
        currentCardIndex = (currentCardIndex + 1) % flashcards.count
        updateCardContent()
    }

    @IBAction func previousCardButtonTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        isTermDisplayed = true
        currentCardIndex = (currentCardIndex - 1 + flashcards.count) % flashcards.count
        updateCardContent()
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
    
    func didCreateNewFlashcard(card: Flashcard) {
        
        flashcards.append(card)
        
       
        let newCardString = "\(card.term)|\(card.definition)"
        
       
        if let currentBody = currentTopic?.largeContentBody, !currentBody.isEmpty {
            currentTopic?.largeContentBody = currentBody + "\n" + newCardString
        } else {
            currentTopic?.largeContentBody = newCardString
        }
        
        
        if let subject = parentSubjectName, let topicName = currentTopic?.name {
            let updatedText = currentTopic?.largeContentBody ?? ""
            DataManager.shared.updateTopicContent(subject: subject, topicName: topicName, newText: updatedText)
        }
        
       
        currentCardIndex = flashcards.count - 1
        isTermDisplayed = true
        updateCardContent(animated: true)
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
}


