//
//  MaterialDetailViewController.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 08/12/25.
//

// MaterialDetailViewController.swift

import UIKit

class MaterialDetailViewController: UIViewController {
    
    // Data Properties passed from SubjectViewController
    var materialName: String?
    var contentData: Topic? // Assuming Topic holds the material details
    
    // UI Elements
    let contentView = UITextView()
    
    // State Tracker
    private var isEditingMode: Bool = false // Tracks View vs. Edit state
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupConstraints() // Define your layout constraints here
        displayContent()
        setupEditButton()
        updateUIForState() // Initial state: View Mode
    }
    
    // MARK: - UI SETUP
    
    func setupUI() {
        contentView.font = UIFont.systemFont(ofSize: 17)
        contentView.isEditable = false // Default to viewing mode
        contentView.dataDetectorTypes = .all // Allows links/phones to be tappable
        contentView.textContainerInset = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)
        view.addSubview(contentView)
    }
    
    func setupConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func displayContent() {
        title = materialName
        
        // Load the actual content text
        if let topic = contentData {
            // Replace this with fetching the full saved text associated with the topic
            contentView.text = "Material Type: \(topic.materialType)\n\n" +
                               "--- Full Content for \(topic.name) ---\n\n" +
                               "1. Separable (1st Order): dx/dy = f(x)g(y)\nSolution: $\\int g(y) dy = \\int f(x) dx + C$\n\n" +
                               "2. Linear (1st Order): $\\mu(x) = e^{\\int P(x) dx}$\nSolution: $y(x) = \\mu(x) \\int (\\mu(x) Q(x)) dx + C$"
        } else {
            contentView.text = "Material not found."
        }
    }
    
}
// MaterialDetailViewController.swift (Continuation)

extension MaterialDetailViewController {
    
    func setupEditButton() {
        // We use a UIBarButtonItem with a title that will change dynamically
        let button = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editButtonTapped))
        navigationItem.rightBarButtonItem = button
    }
    
    @objc func editButtonTapped() {
        // If we are currently editing, we save the content before toggling the state
        if isEditingMode {
            saveChanges()
        }
        
        isEditingMode.toggle()
        updateUIForState()
    }
    
    func updateUIForState() {
        if isEditingMode {
            // EDIT MODE: Show "Done", enable text field, prompt keyboard
            navigationItem.rightBarButtonItem?.title = "Done"
            contentView.isEditable = true
            contentView.becomeFirstResponder()
            
        } else {
            // VIEW MODE: Show "Edit", disable text field, dismiss keyboard
            navigationItem.rightBarButtonItem?.title = "Edit"
            contentView.isEditable = false
            contentView.resignFirstResponder()
        }
    }
    
    func saveChanges() {
        guard let topic = contentData else { return }
        
        let newContent = contentView.text
        
        // 1. Call your DataManager to update the persistent content for this topic
        // DataManager.shared.updateTopicContent(subject: <current_subject>, topicName: topic.name, newText: newContent)
        
        // 2. Notify other screens (like the Subject List) that data has changed
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        
        print("Changes saved for: \(topic.name)")
    }
}
