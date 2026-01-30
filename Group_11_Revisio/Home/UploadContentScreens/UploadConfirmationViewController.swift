import UIKit
import UniformTypeIdentifiers

class UploadConfirmationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    var uploadedContentName: String?
    var parentSubjectName: String?
    
    var fileURLs: [URL] = []
    
    // MARK: - IBOutlets
    @IBOutlet weak var UploadedContent: UITableView!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var addButton: AnyObject!
    
    private let confirmationCellID = "ConfirmationContentCell"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let name = uploadedContentName {
            let dummyURL = URL(fileURLWithPath: name)
            fileURLs = [dummyURL]
        }
        
        setupUI()
        setupTable()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        if let btn = doneButton {
            btn.layer.cornerRadius = 12
            btn.clipsToBounds = true
        }
        
        if let btn = addButton as? UIButton {
            btn.layer.cornerRadius = 12
        }
    }
    
    private func setupTable() {
        guard let table = UploadedContent else { return }
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: confirmationCellID)
        table.separatorStyle = .none
        table.backgroundColor = .clear
    }
    
    // MARK: - Actions
    
    @IBAction func DoneTapped(_ sender: Any) {
        let allFileNames = fileURLs.map { $0.lastPathComponent }
        performSegue(withIdentifier: "showGenerationScreenHome", sender: allFileNames)
    }
    
    // MARK: - Add Button Logic (Action Sheet)
    @IBAction func didTapAddButton(_ sender: Any) {
        let alert = UIAlertController(title: "Add Material", message: "Choose a source", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Document", style: .default, handler: { _ in
            self.openDocumentPicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Photo / Media", style: .default, handler: { _ in
            self.openPhotoPicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Web Link", style: .default, handler: { _ in
            self.showTextInput(title: "Add Web Link", placeholder: "https://example.com")
        }))
        
        alert.addAction(UIAlertAction(title: "Text Note", style: .default, handler: { _ in
            self.showTextInput(title: "Add Quick Note", placeholder: "Enter note title...")
        }))
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(UIColor.systemRed, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        
        if let popover = alert.popoverPresentationController {
            if let btn = sender as? UIView {
                popover.sourceView = btn
                popover.sourceRect = btn.bounds
            } else if let btn = sender as? UIBarButtonItem {
                popover.barButtonItem = btn
            }
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Processing Logic
    private func processNewUpload(name: String) {
        let newURL = URL(fileURLWithPath: name)
        fileURLs.append(newURL)
        JSONDatabaseManager.shared.addUploadedFile(name: name)
        UploadedContent.reloadData()
        
        if !fileURLs.isEmpty {
            let indexPath = IndexPath(row: fileURLs.count - 1, section: 0)
            UploadedContent.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    // MARK: - Helper Methods
    private func openDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .plainText], asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func openPhotoPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showTextInput(title: String, placeholder: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = placeholder }
        
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self.processNewUpload(name: text)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - UITableView Data Source (Card Style)
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileURLs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: confirmationCellID, for: indexPath)
        let url = fileURLs[indexPath.row]
        let fileName = url.lastPathComponent
        
        // --- 1. DETERMINE FILE TYPE ---
        let lowerName = fileName.lowercased()
        var detectedType = "text" // Default
        
        if lowerName.hasSuffix("pdf") {
            detectedType = "pdf document"
        } else if lowerName.contains("http") || lowerName.contains("www.") {
            detectedType = "web link"
        } else if lowerName == "media asset" || lowerName.hasSuffix("jpg") || lowerName.hasSuffix("png") {
            detectedType = "photo/video"
        }
        
        // --- 2. RESTORED SWITCH LOGIC ---
        let symbolName: String
        let tintColor: UIColor
        
        switch detectedType {
        case "pdf document":
            symbolName = "doc.text"
            tintColor = .systemIndigo
        case "web link":
            symbolName = "link"
            tintColor = .systemIndigo
        case "photo/video":
            symbolName = "photo"
            tintColor = .systemIndigo
        default:
            symbolName = "textformat"
            tintColor = .systemIndigo
        }
        
        // --- 3. CARD STYLING ---
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Container
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .secondarySystemGroupedBackground : .systemGray6
        }
        cardView.layer.cornerRadius = 12
        cardView.clipsToBounds = true
        
        cell.contentView.addSubview(cardView)
        
        NSLayoutConstraint.activate([
            cardView.widthAnchor.constraint(equalToConstant: 360),
            cardView.heightAnchor.constraint(equalToConstant: 60),
            cardView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
            cardView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6)
        ])
        
        // Stack (Icon + Text)
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon View
        let icon = UIImageView()
        icon.image = UIImage(systemName: symbolName) // Using the symbol from switch
        icon.tintColor = tintColor // Using the color from switch
        icon.contentMode = .scaleAspectFit
        
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Label
        let label = UILabel()
        label.text = fileName
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 1
        
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(label)
        
        cardView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
        
        return cell
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGenerationScreenHome" {
            if let destinationVC = segue.destination as? GenerateHomeViewController {
                if let nameArray = sender as? [String] {
                    destinationVC.inputSourceData = nameArray
                    destinationVC.contextSubjectTitle = self.parentSubjectName
                }
            }
        }
    }
}

// MARK: - Picker Delegates
extension UploadConfirmationViewController: UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            processNewUpload(name: url.lastPathComponent)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            self.processNewUpload(name: "Media Asset")
        }
    }
}
