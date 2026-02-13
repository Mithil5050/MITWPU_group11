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
        contentView.isEditable = false
        contentView.delegate = self
        setupNavigationButtons()
        displayContent()
    }
    
    // MARK: - Content Loading & Management
    func displayContent() {
        guard let topic = currentTopic else {
            contentView.text = "Cheatsheet or Parent Subject not found."
            return
        }
        
        title = topic.name
        
        var textToDisplay = ""
        
        // 1. Get raw text
        if let directContent = topic.notesContent, !directContent.isEmpty {
            textToDisplay = directContent
        } else if let subject = parentSubjectName {
            textToDisplay = DataManager.shared.getDetailedContent(for: subject, topicName: topic.name)
        }
        
        // 2. Render as Markdown
        if !textToDisplay.isEmpty {
            contentView.attributedText = renderMarkdown(text: textToDisplay)
        } else {
            showPlaceholder()
        }
        
        updateUIForState()
    }
    
    // ✅ NEW: Markdown Renderer
    private func renderMarkdown(text: String) -> NSAttributedString {
        do {
            var options = AttributedString.MarkdownParsingOptions()
            options.interpretedSyntax = .full
            
            var attributedString = try AttributedString(markdown: text, options: options)
            
            // Set Styling
            attributedString.font = .systemFont(ofSize: 16) // Slightly smaller for dense cheatsheets
            attributedString.foregroundColor = .label
            
            return NSAttributedString(attributedString)
        } catch {
            return NSAttributedString(string: text, attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ])
        }
    }
    
    private func showPlaceholder() {
        contentView.text = "Paste or type your cheatsheet here..."
        contentView.textColor = .secondaryLabel
        contentView.font = .systemFont(ofSize: 16)
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
        if isEditingMode { saveChanges() }
        isEditingMode.toggle()
        updateUIForState()
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        saveChanges()
        if isEditingMode {
            isEditingMode = false
            updateUIForState()
        }
        view.endEditing(true)
        showSaveConfirmation()
    }
    
    func showSaveConfirmation() {
        let folderName = parentSubjectName ?? "Files"
        let alert = UIAlertController(title: "Saved!", message: "Material has been successfully saved to '\(folderName)' in Study tab.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if let nav = self.navigationController {
                nav.popToRootViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
        alert.addAction(okAction)
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
                showPlaceholder()
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
