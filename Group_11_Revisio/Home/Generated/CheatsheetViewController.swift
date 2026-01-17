//
//  CheatsheetViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 13/01/26.
//

import UIKit

class CheatsheetViewController: UIViewController {
    
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
            contentView.text = "Cheatsheet or Parent Subject not found."
            return
        }
        
        title = topic.name
        
        let savedContent = DataManager.shared.getDetailedContent(for: subject, topicName: topic.name)
        
        if savedContent.isEmpty {
            contentView.text = "Paste or type your cheatsheet here..."
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
        
        if updatedText == "Paste or type your cheatsheet here..." { return }
        
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
        let shareAction = UIAction(title: "Share Cheatsheet", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            self?.shareContent(self!.editDoneBarButton)
        }
        let pinAction = UIAction(title: "Pin Cheatsheet", image: UIImage(systemName: "pin.fill")) { _ in print("Action: Pin Toggled") }
        let deleteAction = UIAction(title: "Delete Cheatsheet", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in print("Action: Delete Cheatsheet") }
        
        return UIMenu(title: "", children: [UIMenu(title: "Actions", options: .displayInline, children: [shareAction, pinAction]), UIMenu(title: "", options: .displayInline, children: [deleteAction])])
    }

    @IBAction func shareContent(_ sender: UIBarButtonItem) {
        let textToShare = contentView?.text ?? currentTopic?.name ?? "My Cheatsheet"
        let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = sender
        present(activityVC, animated: true)
    }
 
    @objc func editButtonTapped() {
        if isEditingMode {
            // User clicked the Checkmark (Done) on Nav Bar
            saveChanges()
            // ❌ Alert REMOVED from here per your request
        }
        
        isEditingMode.toggle()
        updateUIForState()
    }
    
    // MARK: - ✅ NEW: Bottom Save Button Action
    // Connect this to the button on your View Controller in Storyboard!
    @IBAction func saveButtonTapped(_ sender: Any) {
        // 1. Save the data
        saveChanges()
        
        // 2. Show the confirmation alert
        showSaveConfirmation()
        
        // 3. Optional: Exit editing mode and dismiss keyboard
        if isEditingMode {
            isEditingMode = false
            updateUIForState()
        }
        view.endEditing(true)
    }
    
    // Alert Function
    func showSaveConfirmation() {
        let folderName = parentSubjectName ?? "Files"
        let alert = UIAlertController(title: "Saved!", message: "Material has been successfully saved to '\(folderName)' in Study tab.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func updateUIForState() {
        guard let editButton = editDoneBarButton, let optionsButton = optionsBarButton else { return }

        if isEditingMode {
            editButton.image = UIImage(systemName: "checkmark")
            editButton.title = nil
            contentView.isEditable = true
            contentView.becomeFirstResponder()
            
            if contentView.text == "Paste or type your cheatsheet here..." {
                contentView.text = ""
                contentView.textColor = .label
            }
        } else {
            editButton.image = nil
            editButton.title = "Edit"
            contentView.isEditable = false
            contentView.resignFirstResponder()
            
            if contentView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                contentView.text = "Paste or type your cheatsheet here..."
                contentView.textColor = .secondaryLabel
            }
        }
        optionsButton.menu = buildOptionsMenu()
    }
}

extension CheatsheetViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        saveChanges()
    }
}
