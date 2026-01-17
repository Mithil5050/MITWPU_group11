//
//  NotesViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 14/01/26.
//


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
    // These match the data passed from the Home/Generate screen
    var currentTopic: Topic?
    var parentSubjectName: String?
    
    private var isEditingMode: Bool = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial setup for the TextView
        contentView.isEditable = false
        contentView.delegate = self // Set delegate to handle changes
        
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
        
        // Set Title to Topic Name
        title = topic.name
        
        // Fetch existing content (or largeContentBody if passed directly)
        // If the topic is new, this might be empty, which is fine for a note.
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
              let optionsButton = optionsBarButton else {
            print("CRITICAL ERROR: Edit or Options Bar Button Outlet is NOT CONNECTED in Storyboard!")
            return
        }

        // Configure Edit Button (Toggle Action)
        editButton.target = self
        editButton.action = #selector(editButtonTapped)
        editButton.menu = nil
        
        // Configure Options Button (Menu)
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
        
        let utilityGroup = UIMenu(title: "Actions", options: .displayInline, children: [shareAction, pinAction])
        let destructiveGroup = UIMenu(title: "", options: .displayInline, children: [deleteAction])
        
        return UIMenu(title: "", children: [utilityGroup, destructiveGroup])
    }

    @IBAction func shareContent(_ sender: UIBarButtonItem) {
        let textToShare = contentView?.text ?? currentTopic?.name ?? "My Note"
        let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = sender
        present(activityVC, animated: true)
    }
 
    @objc func editButtonTapped() {
        if isEditingMode {
            saveChanges()
        }
        
        isEditingMode.toggle()
        updateUIForState()
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
            
            // Clear placeholder if editing starts
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
            
            // Restore placeholder if empty
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
    
    func textViewDidChange(_ textView: UITextView) {
        // Optional: Auto-save logic could go here if you don't want to wait for "Done"
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        saveChanges()
    }
}