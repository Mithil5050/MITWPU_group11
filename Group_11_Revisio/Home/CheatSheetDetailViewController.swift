import UIKit

class CheatSheetDetailViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet var cheatSheetTextView: UITextView!
    @IBOutlet var cheatSheetActionMenu: UIBarButtonItem!
    @IBOutlet var cheatSheetEditToggle: UIBarButtonItem!
    
    // MARK: - Properties
    var sheetTitle: String?
    var sheetData: Topic?
    var parentCategory: String?
    
    private var isSheetInEditMode: Bool = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cheatSheetTextView.delegate = self
        cheatSheetTextView.isEditable = false
        
        // iOS 26 Aesthetic: Large Title for Detail Views
        navigationController?.navigationBar.prefersLargeTitles = false
        
        configureCheatSheetUI()
        fetchSheetContent()
    }
    
    private func configureCheatSheetUI() {
        cheatSheetEditToggle.target = self
        cheatSheetEditToggle.action = #selector(handleCheatSheetToggle)
        cheatSheetActionMenu.menu = buildCheatSheetMenu()
        
        navigationItem.rightBarButtonItems = [cheatSheetEditToggle, cheatSheetActionMenu]
        updateSheetStateUI()
    }

    private func buildCheatSheetMenu() -> UIMenu {
        let share = UIAction(title: "Export as PDF", image: UIImage(systemName: "doc.plaintext")) { [weak self] _ in
            self?.executeShareAction()
        }
        
        let delete = UIAction(title: "Delete Sheet", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.confirmDeletion()
        }
        
        return UIMenu(title: "Actions", children: [share, delete])
    }
    
    // MARK: - Data Synchronization
    private func fetchSheetContent() {
        title = sheetTitle ?? "Detail View"
        
        // Use DataManager to retrieve the real-time state
        if let topic = sheetData, let category = parentCategory {
            let content = DataManager.shared.getDetailedContent(for: category, topicName: topic.name)
            if !content.isEmpty {
                cheatSheetTextView.text = content
                return
            }
        }
        
        // Fallback demo content if nothing found
        applyDemoCheatSheetContent()
    }
    
    private func applyDemoCheatSheetContent() {
        cheatSheetTextView.text = """
        CHEAT SHEET
        
        This is placeholder content. Add your notes or cheatsheet here.
        
        Tips:
        - Use concise bullet points.
        - Highlight formulas and key steps.
        - Keep sections short and scannable.
        """
    }

    @objc private func handleCheatSheetToggle() {
        if isSheetInEditMode {
            // User tapped 'Done' - Force a final disk sync
            syncChangesToStorage()
            NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        }
        
        isSheetInEditMode.toggle()
        updateSheetStateUI()
    }
    
    private func updateSheetStateUI() {
        let config = UIImage.SymbolConfiguration(weight: .bold)
        
        if isSheetInEditMode {
            cheatSheetEditToggle.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
            cheatSheetEditToggle.tintColor = .systemGreen
            cheatSheetEditToggle.title = nil
            cheatSheetTextView.isEditable = true
            cheatSheetTextView.becomeFirstResponder()
        } else {
            cheatSheetEditToggle.image = nil
            cheatSheetEditToggle.tintColor = .systemBlue
            cheatSheetEditToggle.title = "Edit"
            cheatSheetTextView.isEditable = false
            cheatSheetTextView.resignFirstResponder()
        }
    }
    
    private func syncChangesToStorage() {
        guard let topic = sheetData, let category = parentCategory else { return }
        let currentText = cheatSheetTextView.text ?? ""
        
        // COMMITTING TO PERSISTENCE
        DataManager.shared.updateTopicContent(subject: category, topicName: topic.name, newText: currentText)
        
        // Provide haptic feedback for successful save (iOS 26 standard)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func confirmDeletion() {
        let alert = UIAlertController(title: "Delete Content?", message: "This action cannot be undone.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            // DataManager.shared.deleteItems logic here
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func executeShareAction() {
        let items = [cheatSheetTextView.text ?? ""]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityVC, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension CheatSheetDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Auto-saving as the user types (Debouncing recommended for large files)
        syncChangesToStorage()
    }
}
