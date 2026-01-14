//
//  AddStudyPlanViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 13/01/26.
//

import UIKit

class AddStudyPlanViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var closeButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    // NEW: Topic Name Text Field
    @IBOutlet weak var topicTextField: UITextField!
    
    @IBOutlet weak var studyGoalButton: UIButton!
    @IBOutlet weak var contentButton: UIButton!
    @IBOutlet weak var daysTextField: UITextField!
    
    @IBOutlet var AddView: UIView!
    
    // MARK: - Properties to store data
    private var selectedGoal: String?
    private var selectedContent: String?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDropdownMenus()
        setupKeyboardDismissal()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // 1. Setup the Card View Background (Adaptive)
        AddView.layer.cornerRadius = 16
        AddView.backgroundColor = .secondarySystemBackground
        
        // 2. NEW: Configure Topic Name Text Field
        setupTextField(topicTextField, placeholder: "Enter Topic Name")
        topicTextField.keyboardType = .default // Standard keyboard for names
        
        // 3. Configure Days Text Field
        setupTextField(daysTextField, placeholder: "e.g. 10")
        daysTextField.keyboardType = .numberPad // Number pad for days
        
        // 4. Style the Dropdown Buttons
        let buttons = [studyGoalButton, contentButton]
        for btn in buttons {
            btn?.layer.cornerRadius = 8
            btn?.clipsToBounds = true
            btn?.backgroundColor = .tertiarySystemFill
            btn?.setTitleColor(.label, for: .normal)
            btn?.contentHorizontalAlignment = .leading
            
            btn?.configuration = .filled()
            btn?.configuration?.baseBackgroundColor = .tertiarySystemFill
            btn?.configuration?.baseForegroundColor = .label
            btn?.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        }
    }
    
    // Helper to style text fields identically
    private func setupTextField(_ textField: UITextField?, placeholder: String) {
        guard let tf = textField else { return }
        tf.layer.cornerRadius = 8
        tf.layer.masksToBounds = true
        tf.backgroundColor = .tertiarySystemFill
        tf.textColor = .label
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
        )
        tf.delegate = self
    }

    // MARK: - Dropdown Logic (UIMenu)
    private func setupDropdownMenus() {
        
        // A. Study Goal Options
        let goal1 = UIAction(title: "Prepare for Exam", image: UIImage(systemName: "studentdesk")) { _ in
            self.updateButtonSelection(self.studyGoalButton, title: "Prepare for Exam")
            self.selectedGoal = "Prepare for Exam"
        }
        let goal2 = UIAction(title: "Learn New Skill", image: UIImage(systemName: "book")) { _ in
            self.updateButtonSelection(self.studyGoalButton, title: "Learn New Skill")
            self.selectedGoal = "Learn New Skill"
        }
        let goal3 = UIAction(title: "Revision", image: UIImage(systemName: "arrow.counterclockwise")) { _ in
            self.updateButtonSelection(self.studyGoalButton, title: "Revision")
            self.selectedGoal = "Revision"
        }
        
        studyGoalButton.menu = UIMenu(title: "Select Goal", children: [goal1, goal2, goal3])
        studyGoalButton.showsMenuAsPrimaryAction = true
        studyGoalButton.changesSelectionAsPrimaryAction = false
        
        // B. Content Options
        let content1 = UIAction(title: "Big Data Notes") { _ in
            self.updateButtonSelection(self.contentButton, title: "Big Data Notes")
            self.selectedContent = "Big Data Notes"
        }
        let content2 = UIAction(title: "Swift Fundamentals") { _ in
            self.updateButtonSelection(self.contentButton, title: "Swift Fundamentals")
            self.selectedContent = "Swift Fundamentals"
        }
        
        contentButton.menu = UIMenu(title: "Select Content", children: [content1, content2])
        contentButton.showsMenuAsPrimaryAction = true
    }
    
    private func updateButtonSelection(_ button: UIButton?, title: String) {
        button?.setTitle(title, for: .normal)
        button?.setTitleColor(.label, for: .normal)
        button?.configuration?.baseForegroundColor = .label
    }

    // MARK: - Actions
    
    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        // 1. Validate ALL Inputs (Topic, Goal, Content, Days)
        guard let topic = topicTextField.text, !topic.isEmpty,
              let goal = selectedGoal,
              let content = selectedContent,
              let daysText = daysTextField.text, !daysText.isEmpty,
              let days = Int(daysText) else {
            
            let alert = UIAlertController(title: "Missing Information", message: "Please fill in all fields (Topic, Goal, Content, Days).", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // 2. Success Logic
        print("✅ Plan Created!")
        print("Topic: \(topic)")
        print("Goal: \(goal)")
        print("Content: \(content)")
        print("Days: \(days)")
        
        // 3. Dismiss
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardDismissal() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flexSpace, doneBtn]
        
        // Add toolbar to both text fields
        daysTextField.inputAccessoryView = toolbar
        topicTextField.inputAccessoryView = toolbar // Add to topic too
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
