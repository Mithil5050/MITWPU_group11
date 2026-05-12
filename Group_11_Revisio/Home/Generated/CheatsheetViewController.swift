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
    private var studyTimer: Timer?
    private let studyThreshold: TimeInterval = 60.0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.isEditable = false
        contentView.delegate = self
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
                ProgressDataManager.shared.logSession(minutes: 1.0, category: "Study")
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
        guard let topic = currentTopic else { return }
        // Multi-line title so long names never truncate
        let titleLabel = UILabel()
        titleLabel.text = topic.name
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
        
        var textToDisplay = ""
        if let directContent = topic.cheatsheetContent, !directContent.isEmpty {
            textToDisplay = directContent
        } else if let subject = parentSubjectName {
            textToDisplay = DataManager.shared.getDetailedContent(for: subject, topicName: topic.name)
        }

        if !textToDisplay.isEmpty {
            let fullAttributedString = NSMutableAttributedString(string: textToDisplay)
            let range = NSRange(location: 0, length: textToDisplay.utf16.count)
            
            // Slightly smaller base font for cheatsheet tables
            fullAttributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular), range: range)
            fullAttributedString.addAttribute(.foregroundColor, value: UIColor.label, range: range)

            let lines = textToDisplay.components(separatedBy: "\n")
            var currentOffset = 0
            
            for line in lines {
                if line.hasPrefix("##") || line.hasPrefix("###") {
                    let lineRange = NSRange(location: currentOffset, length: line.utf16.count)
                    fullAttributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: 17, weight: .bold), range: lineRange)
                    fullAttributedString.addAttribute(.foregroundColor, value: UIColor.systemIndigo, range: lineRange)
                }
                currentOffset += line.utf16.count + 1
            }
            
            contentView.attributedText = fullAttributedString
        } else {
            showPlaceholder()
        }
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
