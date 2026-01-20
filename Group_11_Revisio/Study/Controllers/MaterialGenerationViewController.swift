//
//  MaterialGenerationViewController.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 13/01/26.
//

import UIKit

class MaterialGenerationViewController: UIViewController {
    
    @IBOutlet weak var contentView: UITextView!
    
    @IBOutlet weak var optionsBarButton: UIBarButtonItem!
    
    @IBOutlet weak var editDoneBarButton: UIBarButtonItem!
    
    @IBOutlet weak var saveButton: UIButton!
    var contentData: Topic?
    var parentSubjectName: String?
    var materialType: String?
    private var isEditingMode: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.isEditable = false
                contentView.delegate = self
                
                setupNavigationButtons()
                displayGeneratedContent()
                
               
                saveButton.layer.cornerRadius = 12

    }
    
    @IBAction func saveTapped(_ sender: Any) {
        saveChanges()
            
            
            if let topic = contentData, let subject = parentSubjectName {
                
                DataManager.shared.addTopic(to: subject, topic: topic)
            }
            
            
            self.navigationController?.popViewController(animated: true)
    }
    func displayGeneratedContent() {
        
        self.title = contentData?.name ?? "Material"
        
        guard let topic = contentData else { return }

      
        if materialType == "Notes" {
            contentView.text = topic.notesContent
        } else if materialType == "Cheatsheet" {
            contentView.text = topic.cheatsheetContent
        } else {
           
            contentView.text = topic.largeContentBody
        }
    }
        // MARK: - Navigation Bar Actions
        func setupNavigationButtons() {
            guard let editButton = editDoneBarButton,
                  let optionsButton = optionsBarButton else { return }

            editButton.target = self
            editButton.action = #selector(editButtonTapped)
            
            optionsButton.menu = buildOptionsMenu()
            
            navigationItem.rightBarButtonItems = [editButton, optionsButton]
            updateUIForState()
        }

        func buildOptionsMenu() -> UIMenu {
            let shareAction = UIAction(title: "Share Material", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.shareContent(self!.optionsBarButton)
            }
            
            let pinAction = UIAction(title: "Pin to Top", image: UIImage(systemName: "pin.fill")) { _ in }
            
            let utilityGroup = UIMenu(title: "Actions", options: .displayInline, children: [shareAction, pinAction])
            return UIMenu(title: "", children: [utilityGroup])
        }

        @objc func editButtonTapped() {
            if isEditingMode { saveChanges() }
            isEditingMode.toggle()
            updateUIForState()
        }

        func updateUIForState() {
            guard let editButton = editDoneBarButton else { return }

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
    func shareContent(_ sender: UIBarButtonItem) {
            let textToShare = contentView.text ?? "Study Material"
            let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = sender
            present(activityVC, animated: true)
        }
    }
extension MaterialGenerationViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        saveChanges()
    }
}
