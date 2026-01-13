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
                contentView.delegate = self // Make sure to set delegate for auto-save
                
                setupNavigationButtons()
                displayGeneratedContent()
                
                // Style your bottom button
                saveButton.layer.cornerRadius = 12

        // Do any additional setup after loading the view.
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        saveChanges()
            
            // 2. Add the topic to the specific Subject folder in the library
            if let topic = contentData, let subject = parentSubjectName {
                // This ensures the topic is physically added to the Subject's material list
                DataManager.shared.addTopic(to: subject, topic: topic)
            }
            
            // 3. Go back to the previous screen
            self.navigationController?.popViewController(animated: true)
    }
    func displayGeneratedContent() {
        // This ensures the title is just the Source Name as requested
        self.title = contentData?.name ?? "Material"
        
        guard let topic = contentData else { return }

        // Logic to pick which field to show based on what button was tapped
        if materialType == "Notes" {
            contentView.text = topic.notesContent
        } else if materialType == "Cheatsheet" {
            contentView.text = topic.cheatsheetContent
        } else {
            // Fallback for Quizzes or other types
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
        
        // Using the explicit shared instance and named parameters
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension MaterialGenerationViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        saveChanges() // Auto-save while user types
    }
}
