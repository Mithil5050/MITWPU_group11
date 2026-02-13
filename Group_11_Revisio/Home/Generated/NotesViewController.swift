import UIKit

class NotesViewController: UIViewController {
    
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
            contentView.text = "Note or Parent Subject not found."
            return
        }
        
        title = topic.name
        
        var textToDisplay = ""
        
        // 1. Get the raw text (AI or Database)
        if let directContent = topic.notesContent, !directContent.isEmpty {
            textToDisplay = directContent
        } else if let subject = parentSubjectName {
            textToDisplay = DataManager.shared.getDetailedContent(for: subject, topicName: topic.name)
        }
        
        // 2. Render it as Markdown (Bold, Headings, etc.)
        if !textToDisplay.isEmpty {
            contentView.attributedText = renderMarkdown(text: textToDisplay)
        } else {
            showPlaceholder()
        }
        
        updateUIForState()
    }
    
    // ✅ NEW: Helper to convert ** and ## into Bold and Headings
    private func renderMarkdown(text: String) -> NSAttributedString {
        do {
            var options = AttributedString.MarkdownParsingOptions()
            options.interpretedSyntax = .full // Allow all markdown features
            
            var attributedString = try AttributedString(markdown: text, options: options)
            
            // Set Base Font (so it's not tiny)
            attributedString.font = .systemFont(ofSize: 17)
            attributedString.foregroundColor = .label // Adapts to Dark/Light mode
            
            return NSAttributedString(attributedString)
        } catch {
            // Fallback if parsing fails
            return NSAttributedString(string: text, attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.label
            ])
        }
    }
    
    private func showPlaceholder() {
        contentView.text = "Start typing your notes here..."
        contentView.textColor = .secondaryLabel
        contentView.font = .systemFont(ofSize: 17)
    }
    
    func saveChanges() {
        guard let topic = currentTopic,
              let subject = parentSubjectName,
              let updatedText = contentView.text else { return }
        
        if updatedText == "Start typing your notes here..." { return }
        
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
        let shareAction = UIAction(title: "Share Note", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            self?.shareContent(self!.editDoneBarButton)
        }
        let pinAction = UIAction(title: "Pin Note", image: UIImage(systemName: "pin.fill")) { _ in print("Action: Pin Toggled") }
        let deleteAction = UIAction(title: "Delete Note", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in print("Action: Delete Note") }
        
        return UIMenu(title: "", children: [
            UIMenu(title: "Actions", options: .displayInline, children: [shareAction, pinAction]),
            UIMenu(title: "", options: .displayInline, children: [deleteAction])
        ])
    }

    @IBAction func shareContent(_ sender: UIBarButtonItem) {
        let textToShare = contentView?.text ?? currentTopic?.name ?? "My Note"
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
        let alert = UIAlertController(title: "Saved!", message: "Note has been successfully saved to '\(folderName)' in Study tab.", preferredStyle: .alert)
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
            
            // When editing, remove placeholder if present
            if contentView.text == "Start typing your notes here..." {
                contentView.text = ""
                contentView.textColor = .label
                contentView.font = .systemFont(ofSize: 17)
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

extension NotesViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        saveChanges()
    }
}
