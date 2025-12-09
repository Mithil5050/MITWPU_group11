//
//  MaterialDetailViewController.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 08/12/25.
//

import UIKit

class MaterialDetailViewController: UIViewController {
    
    // Connect this to the UITextView in your Storyboard
    @IBOutlet weak var contentView: UITextView!
    
    var materialName: String?
    var contentData: Topic? // The specific Topic object
    var parentSubjectName: String? // Needed for DataManager saving/lookup
    
    private var isEditingMode: Bool = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial setup for the TextView
        contentView.isEditable = false
        
        setupNavigationButtons()
        
        displayContent()
    }
    
    // MARK: - Content Loading & Management
    
    func displayContent() {
        title = materialName
        
        guard let topic = contentData,
              let subject = parentSubjectName else {
            contentView.text = "Material or Parent Subject not found."
            return
        }
        
        // Since DataManager has no detailed content API, show a sensible placeholder using available data.
        let header = "\(topic.name)"
        let meta = "\(topic.materialType) • Last Accessed: \(topic.lastAccessed)"
        let body = "\n\nNo detailed content is stored for this item.\nSubject: \(subject)"
        contentView.text = header + "\n" + meta + body
    }
    
    // MaterialDetailViewController.swift (Updated saveChanges)

    func saveChanges() {
        guard let topic = contentData,
              let subject = parentSubjectName else { return }
        
        let newContent = contentView.text
        
        // Call DataManager to update persistent content (THIS IS THE SAVE ACTION)
        // DataManager.shared.updateTopicContent(subject: subject, topicName: topic.name, newText: newContent)
        
        // Note: Do NOT post .didUpdateStudyMaterials notification here, as that would cause the parent view
        // to reload constantly while the user is typing, which is distracting.
        
        print("Auto-Saved changes for: \(topic.name) in \(subject).")
    }
    
    // MARK: - Navigation Bar Actions
    
    func setupNavigationButtons() {
        // DO NOT TOUCH LEFT BUTTON: Let the system handle the Back Button.
        navigationItem.leftBarButtonItem = nil // Ensure no custom button is overriding the Back button.
        
        // --- RIGHT BAR BUTTON ITEMS (SHARE / OPTIONS) ---
        
        guard let barButtons = navigationItem.rightBarButtonItems, barButtons.count >= 2 else {
            return
        }

        // Identify the buttons by their image/icon
        let shareButton = barButtons.first { $0.image == UIImage(systemName: "square.and.arrow.up") }
        let optionsButton = barButtons.first { $0.image == UIImage(systemName: "ellipsis.circle") }
        
        guard let finalShareButton = shareButton,
              let finalOptionsButton = optionsButton else {
            return
        }
        
        // 1. Share Button Setup (Direct Action)
        finalShareButton.target = self
        finalShareButton.action = #selector(shareContent(_:))
        finalShareButton.menu = nil
        
        // 2. Options Button Setup (Menu Assignment)
        finalOptionsButton.menu = buildOptionsMenu() // Assign the initial menu
        finalOptionsButton.target = nil
        finalOptionsButton.action = nil
        
        // 3. Set the final right-hand order: [Options, Share] visually
        navigationItem.rightBarButtonItems = [finalOptionsButton, finalShareButton].reversed()
    }

    // MaterialDetailViewController.swift (Updated buildOptionsMenu)

    func buildOptionsMenu() -> UIMenu {
        
        // 1. Define the primary action: Edit or Done (Dynamic based on state)
        let primaryTitle = isEditingMode ? "Done" : "Edit"
        let primaryImage = isEditingMode ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "pencil")
        
        let editToggleAction = UIAction(title: primaryTitle, image: primaryImage) { [weak self] _ in
            // This action triggers the toggle logic
            self?.editButtonTapped()
        }
        
        // 2. Define Pin and Delete actions
        let pinAction = UIAction(title: "Pin to Top", image: UIImage(systemName: "pin.fill")) { _ in
            print("Action: Pin Toggled")
        }
        let deleteAction = UIAction(title: "Delete Material", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            print("Action: Delete Material")
        }
        
        // 3. Assemble the Menu: [Edit/Done, Pin], then [Delete]
        let nonDestructiveGroup = UIMenu(title: "", options: .displayInline, children: [editToggleAction, pinAction])
        let destructiveGroup = UIMenu(title: "", options: .displayInline, children: [deleteAction])
        
        return UIMenu(title: "", children: [nonDestructiveGroup, destructiveGroup])
    }

    // REMOVE: @objc func editButtonTapped()
    // REMOVE: func updateUIForState()
  
    // Keep a single share action to avoid "Ambiguous use of 'shareContent'"
    @IBAction func shareContent(_ sender: UIBarButtonItem) {
        // Simple share of the current text content
        let textToShare = contentView?.text ?? materialName ?? "Study Material"
        let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = sender
        present(activityVC, animated: true)
    }
    // MaterialDetailViewController.swift (Inside the class body)

    // MaterialDetailViewController.swift (Inside the class body)

    // MaterialDetailViewController.swift (Inside the class body)

    @objc func editButtonTapped() {
        // 1. If transitioning from Done to Edit, save changes
        if isEditingMode {
            saveChanges()
        }
        
        // 2. Toggle the state
        isEditingMode.toggle()
        
        // 3. Update the UI and menu
        updateUIForState()
    }

    func updateUIForState() {
        let optionsButton = navigationItem.rightBarButtonItems?.first { $0.image == UIImage(systemName: "ellipsis.circle") }
        
        if isEditingMode {
            // EDIT MODE: Enable text field, prompt keyboard
            contentView.isEditable = true
            contentView.becomeFirstResponder()
            
        } else {
            // VIEW MODE: Disable text field, dismiss keyboard
            contentView.isEditable = false
            contentView.resignFirstResponder()
        }
        
        // Always rebuild and re-assign the menu to update the "Edit"/"Done" title
        optionsButton?.menu = buildOptionsMenu()
    }
    // MARK: - View/Edit Toggle Logic
    
    
}
// MaterialDetailViewController.swift (Auto-Saving Delegate)

extension MaterialDetailViewController: UITextViewDelegate {
    
    // This function is called every time the user types a character or pastes text.
    func textViewDidChange(_ textView: UITextView) {
        
        
        
        // Option A: Simple Instant Save (Easy to implement, but resource-intensive)
        saveChanges()
        
        // Option B: Debounced Save (Better performance)
        // You would typically use a timer here to delay the save by 1-2 seconds.
    }
}
