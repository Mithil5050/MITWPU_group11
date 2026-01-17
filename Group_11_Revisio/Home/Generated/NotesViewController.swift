//
//  NotesViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 13/01/26.
//

import UIKit

class NotesViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var contentView: UITextView!
    @IBOutlet var optionsBarButton: UIBarButtonItem!
    @IBOutlet var editDoneBarButton: UIBarButtonItem!
    
    // MARK: - Data Properties
    var currentTopic: Topic?
    var parentSubjectName: String?
    
    private var isEditingMode: Bool = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial setup for the TextView
        contentView.isEditable = false
        contentView.delegate = self
        
        setupNavigationButtons()
        displayContent()
    }
    
    // MARK: - Content Loading & Management
    func displayContent() {
        guard let topic = currentTopic,
              let subject = parentSubjectName else {
            contentView.text = "Note or Parent Subject not found."
            return
        }
        
        title = topic.name
        
        let savedContent = DataManager.shared.getDetailedContent(for: subject, topicName: topic.name)
        
        if savedContent.isEmpty {
            contentView.text = "Start typing your notes here..."
            contentView.textColor = .secondaryLabel
        } else {
            contentView.text = savedContent
            contentView.textColor = .label
        }
        
        updateUIForState()
    }
    
    func saveChanges() {
        guard let topic = currentTopic,
              let subject = parentSubjectName,
              let updatedText = contentView.text else { return }
        
        // Avoid saving the placeholder text
        if updatedText == "Start typing your notes here..." { return }
        
        DataManager.shared.updateTopicContent(subject: subject, topicName: topic.name, newText: updatedText)
    }
    
    // MARK: - Navigation Bar Actions
    func setupNavigationButtons() {
        guard let editButton = editDoneBarButton,
              let optionsButton = optionsBarButton else { return }

        // Configure Edit Button
        editButton.target = self
        editButton.action = #selector(editButtonTapped)
        editButton.menu = nil
        
        // Configure Options Button
        optionsButton.target = nil
        optionsButton.action = nil
        optionsButton.menu = buildOptionsMenu()
      
        navigationItem.rightBarButtonItems = [editButton, optionsButton]
        
        updateUIForState()
    }
    
    func buildOptionsMenu() -> UIMenu {
        
        let shareAction = UIAction(title: "Share Note", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            self?.shareContent(self!.editDoneBarButton)
        }
        
        let pinAction = UIAction(title: "Pin Note", image: UIImage(systemName: "pin.fill")) { _ in
            print("Action: Pin Toggled")
        }
        
        let deleteAction = UIAction(title: "Delete Note", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            print("Action: Delete Note")
        }
        
        return UIMenu(title: "", children: [
            UIMenu(title: "Actions", options: .displayInline, children: [shareAction, pinAction]),
            UIMenu(title: "", options: .displayInline, children: [deleteAction])
        ])
    }

    @IBAction func shareContent(_ sender: UIBarButtonItem) {
        let textToShare = contentView?.text ?? currentTopic?.name ?? "My Note"
        let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = sender
        present(activityVC, animated: true)
    }
 
    @objc func editButtonTapped() {
        if isEditingMode {
            // User clicked the Checkmark (Done)
            saveChanges()
            // No alert here, just silent save
        }
        
        isEditingMode.toggle()
        updateUIForState()
    }
    
    // MARK: - ✅ NEW: Bottom Save Button Action
    // IMPORTANT: Connect this to the button in your Storyboard!
    @IBAction func saveButtonTapped(_ sender: Any) {
        // 1. Save data
        saveChanges()
        
        // 2. Show Alert
        showSaveConfirmation()
        
        // 3. Exit edit mode cleanly
        if isEditingMode {
            isEditingMode = false
            updateUIForState()
        }
        view.endEditing(true)
    }
    
    // Alert Function
    func showSaveConfirmation() {
        let folderName = parentSubjectName ?? "Files"
        
        let alert = UIAlertController(
            title: "Saved!",
            message: "Note has been successfully saved to '\(folderName)' in Study tab.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }

    func updateUIForState() {
        guard let editButton = editDoneBarButton,
              let optionsButton = optionsBarButton else { return }

        if isEditingMode {
            // Editing State
            editButton.image = UIImage(systemName: "checkmark")
            editButton.title = nil
            contentView.isEditable = true
            contentView.becomeFirstResponder()
            
            if contentView.text == "Start typing your notes here..." {
                contentView.text = ""
                contentView.textColor = .label
            }
            
        } else {
            // Viewing State
            editButton.image = nil
            editButton.title = "Edit"
            contentView.isEditable = false
            contentView.resignFirstResponder()
            
            if contentView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                contentView.text = "Start typing your notes here..."
                contentView.textColor = .secondaryLabel
            }
        }
        
        optionsButton.menu = buildOptionsMenu()
    }
}

// MARK: - UITextViewDelegate
extension NotesViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        saveChanges()
    }
}
