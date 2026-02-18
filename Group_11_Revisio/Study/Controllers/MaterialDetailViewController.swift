//
//  MaterialDetailViewController.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 08/12/25.
//

import UIKit

class MaterialDetailViewController: UIViewController {
    
    
    @IBOutlet weak var contentView: UITextView!
    
    @IBOutlet var optionsBarButton: UIBarButtonItem!
    
    @IBOutlet var editDoneBarButton: UIBarButtonItem!
    
    var materialType: String?
    var materialName: String?
    var contentData: Topic?
    var parentSubjectName: String?
    
    private var isEditingMode: Bool = false
    private var studyTimer: Timer?
    private let studyThreshold: TimeInterval = 60.0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        contentView.isEditable = false
        
        setupNavigationButtons()
        
        displayContent()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 1. Force clear any existing timer
        studyTimer?.invalidate()
        
        print("⏳ Focus Timer Started: 60 Seconds")
        
        // 2. Create the timer
        let timer = Timer(timeInterval: studyThreshold, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                await RevisioManager.shared.earnXP(amount: 10, reason: "Deep Study Focus")
                print("✅ Success: 1 Minute Focus Reward Given")
                self.studyTimer = nil
            }
        }
        
        // 3. CRITICAL: Add to .common mode so scrolling doesn't stop the clock
        RunLoop.current.add(timer, forMode: .common)
        self.studyTimer = timer
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 4. Kill the timer if they leave before 60s
        studyTimer?.invalidate()
        studyTimer = nil
    }
    // MARK: - Content Loading & Management
    
    func displayContent() {
        
        title = materialName ?? materialType
        
        guard let topic = contentData else {
            contentView.text = "Topic not found."
            return
        }

       
        if materialType == "Notes" {
            contentView.text = topic.notesContent
        } else if materialType == "Cheatsheet" {
            contentView.text = topic.cheatsheetContent
        } else {
          
            if let subject = parentSubjectName {
                contentView.text = DataManager.shared.getDetailedContent(for: subject, topicName: topic.name)
            }
        }
        
        updateUIForState()
    }
    
    
    func saveChanges() {
        guard let topic = contentData,
              let subject = parentSubjectName,
              let type = materialType,
              let updatedText = contentView.text else { return }
        
        
        DataManager.shared.updateTopicContent(
            subject: subject,
            topicName: topic.name,
            newText: updatedText,
            type: type
        )
    }
    
    // MARK: - Navigation Bar Actions
    
    func setupNavigationButtons() {
        
        
        guard let editButton = editDoneBarButton,
              let optionsButton = optionsBarButton else {
            print("CRITICAL ERROR: Edit or Options Bar Button Outlet is NOT CONNECTED in Storyboard!")
            return
        }

     
        editButton.target = self
        editButton.action = #selector(editButtonTapped)
        editButton.menu = nil
        
       
        optionsButton.target = nil
        optionsButton.action = nil
        optionsButton.menu = buildOptionsMenu()
      
        navigationItem.rightBarButtonItems = [editButton, optionsButton]
        
        
        updateUIForState()
    }
   

    func buildOptionsMenu() -> UIMenu {
        
       
        let shareAction = UIAction(title: "Share Material", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            
            self?.shareContent(self!.editDoneBarButton)
        }
        
       
        let pinAction = UIAction(title: "Pin to Top", image: UIImage(systemName: "pin.fill")) { _ in
            print("Action: Pin Toggled")
        }
        let deleteAction = UIAction(title: "Delete Material", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            print("Action: Delete Material")
        }
        
       
        let utilityGroup = UIMenu(title: "Actions", options: .displayInline, children: [shareAction, pinAction])
        let destructiveGroup = UIMenu(title: "", options: .displayInline, children: [deleteAction])
        
        return UIMenu(title: "", children: [utilityGroup, destructiveGroup])
    }

    
    @IBAction func shareContent(_ sender: UIBarButtonItem) {
        
        let textToShare = contentView?.text ?? materialName ?? "Study Material"
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
            
            editButton.image = UIImage(systemName: "checkmark")
            editButton.title = nil
            contentView.isEditable = true
            contentView.becomeFirstResponder()
            
        } else {
            
            editButton.image = nil
            editButton.title = "Edit"
            contentView.isEditable = false
            contentView.resignFirstResponder()
        }
        
        
        optionsButton.menu = buildOptionsMenu()
    }
    
    
}


extension MaterialDetailViewController: UITextViewDelegate {
    
    
    func textViewDidChange(_ textView: UITextView) {
        
        
        
        
        saveChanges()
        
        
    }
}
