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
    
    @IBOutlet var optionsBarButton: UIBarButtonItem!
    
    @IBOutlet var editDoneBarButton: UIBarButtonItem!
    
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
        
        
        contentView.text = DataManager.shared.getDetailedContent(for: subject, topicName: topic.name)
        
        // Set up the current editing state based on the loaded content/material type
        updateUIForState()
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
        
        // Check if the buttons were correctly connected via outlets
        guard let editButton = editDoneBarButton,
              let optionsButton = optionsBarButton else {
            print("CRITICAL ERROR: Edit or Options Bar Button Outlet is NOT CONNECTED in Storyboard!")
            return
        }

        // --- 1. CONFIGURE EDIT/DONE BUTTON (The Toggle) ---
        editButton.target = self
        editButton.action = #selector(editButtonTapped)
        editButton.menu = nil
        
        // --- 2. CONFIGURE OPTIONS BUTTON (The Menu) ---
        optionsButton.target = nil
        optionsButton.action = nil
        optionsButton.menu = buildOptionsMenu()
        
        // --- 3. FINAL ARRAY ASSIGNMENT (THE ORDER FIX) ---
        
        // If [options, edit] puts 'options' on the right, we must swap them in the array.
        // We are forcing the array order to be [Edit/Done, Options] to fix the display.
        navigationItem.rightBarButtonItems = [editButton, optionsButton]
        
        // 4. Initialize the correct state (Fixes "Edit" vs. "Tick" image on load)
        updateUIForState()
    }
    // MaterialDetailViewController.swift (Updated buildOptionsMenu)

    func buildOptionsMenu() -> UIMenu {
        
        // 1. Define the nested Share Action
        let shareAction = UIAction(title: "Share Material", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            // Use the editDoneBarButton reference for the popover anchor
            self?.shareContent(self!.editDoneBarButton)
        }
        
        // 2. Define Pin and Delete actions
        let pinAction = UIAction(title: "Pin to Top", image: UIImage(systemName: "pin.fill")) { _ in
            print("Action: Pin Toggled")
        }
        let deleteAction = UIAction(title: "Delete Material", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            print("Action: Delete Material")
        }
        
        // 3. Assemble the Menu: [Share, Pin], then [Delete]. Edit is NOT included here.
        let utilityGroup = UIMenu(title: "Actions", options: .displayInline, children: [shareAction, pinAction])
        let destructiveGroup = UIMenu(title: "", options: .displayInline, children: [deleteAction])
        
        return UIMenu(title: "", children: [utilityGroup, destructiveGroup])
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
        
        guard let editButton = editDoneBarButton,
              let optionsButton = optionsBarButton else { return }

        if isEditingMode {
            // EDIT MODE: Change to Tick icon, enable text field
            editButton.image = UIImage(systemName: "checkmark") // Better visibility
            editButton.title = nil
            contentView.isEditable = true
            contentView.becomeFirstResponder()
            
        } else {
            // VIEW MODE: Change to Edit text, disable text field
            editButton.image = nil
            editButton.title = "Edit"
            contentView.isEditable = false
            contentView.resignFirstResponder()
        }
        
        // Rebuild and re-assign the Options Menu
        optionsButton.menu = buildOptionsMenu()
    }
    
    
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
