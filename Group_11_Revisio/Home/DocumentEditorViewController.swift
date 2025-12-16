//
//  DocumentEditorViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 16/12/25.
//

import UIKit

class DocumentEditorViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var primaryTextView: UITextView!
    @IBOutlet var actionMenuButton: UIBarButtonItem!
    @IBOutlet var toggleEditButton: UIBarButtonItem!
    
    // MARK: - Properties
    var documentTitle: String?
    var documentData: Topic?
    var categoryReference: String?
    
    private var isEditingActive: Bool = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UITextView Setup
        primaryTextView.delegate = self
        primaryTextView.isEditable = false
        primaryTextView.font = UIFont.preferredFont(forTextStyle: .body)
        primaryTextView.adjustsFontForContentSizeCategory = true
        
        configureNavigationInterface()
        loadDocumentContent()
    }
    
    // MARK: - UI Configuration
    private func configureNavigationInterface() {
        // Assign Target-Actions
        toggleEditButton.target = self
        toggleEditButton.action = #selector(handleEditToggle)
        
        // Setup the modern iOS 26 Menu on the ellipsis button
        actionMenuButton.menu = generateDocumentMenu()
        
        // Ensure standard iOS layout: [Edit/Checkmark, Options]
        navigationItem.rightBarButtonItems = [toggleEditButton, actionMenuButton]
        
        refreshInterfaceState()
    }
    
    private func generateDocumentMenu() -> UIMenu {
        // Share Action
        let shareAction = UIAction(title: "Share Material", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            self?.initiateShareSheet()
        }
        
        // Utility Actions
        let pinAction = UIAction(title: "Pin to Dashboard", image: UIImage(systemName: "pin")) { _ in
            print("Document Pinned")
        }
        
        // Destructive Action
        let deleteAction = UIAction(title: "Delete Document", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            print("Document Deleted")
        }
        
        let utilityGroup = UIMenu(title: "", options: .displayInline, children: [shareAction, pinAction])
        
        return UIMenu(title: "Document Options", children: [utilityGroup, deleteAction])
    }
    
    // MARK: - Logic & Data Persistence
    private func loadDocumentContent() {
        // Set the Navigation Title
        title = documentTitle ?? "Big Data Notes"
        
        // Attempt to fetch existing data from DataManager
        if let topic = documentData, let category = categoryReference {
            let savedContent = DataManager.shared.getDetailedContent(for: category, topicName: topic.name)
            if !savedContent.isEmpty {
                primaryTextView.text = savedContent
                return
            }
        }
        
        // Fallback to Demo Content if no data is found
        applyDemoContent()
    }
    
    private func applyDemoContent() {
        primaryTextView.text = """
        BIG DATA: AN ARCHITECTURAL OVERVIEW
        
        Definition:
        Big Data refers to datasets whose size, complexity, and velocity exceed the capabilities of traditional database systems. 
        
        The 5 V's of Big Data:
        1. Volume: The scale of data (Terabytes to Zettabytes).
        2. Velocity: The speed of data generation and processing.
        3. Variety: Structured, Semi-structured, and Unstructured formats.
        4. Veracity: The reliability and accuracy of the information.
        5. Value: Turning raw data into actionable insights.
        
        Core Technologies:
        - Storage: HDFS, NoSQL (MongoDB, Cassandra).
        - Processing: Apache Spark, MapReduce.
        - Analysis: Real-time stream processing.
        """
    }
    
    @objc private func handleEditToggle() {
        if isEditingActive {
            persistChanges()
        }
        
        isEditingActive.toggle()
        refreshInterfaceState()
    }
    
    private func refreshInterfaceState() {
        if isEditingActive {
            // Edit Mode: Show Checkmark, enable keyboard
            toggleEditButton.image = UIImage(systemName: "checkmark.circle.fill")
            toggleEditButton.title = nil
            primaryTextView.isEditable = true
            primaryTextView.becomeFirstResponder()
        } else {
            // View Mode: Show "Edit" text, disable keyboard
            toggleEditButton.image = nil
            toggleEditButton.title = "Edit"
            primaryTextView.isEditable = false
            primaryTextView.resignFirstResponder()
        }
    }
    
    private func persistChanges() {
        guard let topic = documentData, let category = categoryReference else { return }
        let updatedText = primaryTextView.text ?? ""
        
        // Save to DataManager
        // DataManager.shared.updateTopicContent(subject: category, topicName: topic.name, newText: updatedText)
        print("Auto-saved changes for: \(topic.name)")
    }
    
    private func initiateShareSheet() {
        let textToShare = primaryTextView.text ?? ""
        let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        
        // Anchor for iPad support
        activityVC.popoverPresentationController?.barButtonItem = actionMenuButton
        present(activityVC, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension DocumentEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Continuous synchronization during editing
        persistChanges()
    }
}
