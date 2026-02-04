import UIKit
import UniformTypeIdentifiers

class UploadConfirmationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var UploadedContent: UITableView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    // MARK: - Properties
    var incomingDataPath: String?
    var filesToSave: [URL] = []
    
    private let confirmationCellID = "ConfirmationContentCell"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTable()
        processIncomingData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        if let btn = doneButton {
            btn.layer.cornerRadius = 12
            btn.clipsToBounds = true
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
    
    // MARK: - Data Processing
    func processIncomingData() {
        guard let dataString = incomingDataPath else { return }
        
        // 1. Check if it is a real file on disk
        if FileManager.default.fileExists(atPath: dataString) {
            let url = URL(fileURLWithPath: dataString)
            filesToSave.append(url)
        } else {
            // 2. Otherwise, treat as Text or Link -> Create Temp File
            processTextOrLinkInput(text: dataString)
        }
        UploadedContent.reloadData()
    }
    
    private func processTextOrLinkInput(text: String) {
        let tempDir = FileManager.default.temporaryDirectory
        let isLink = text.lowercased().hasPrefix("http") || text.lowercased().hasPrefix("www")
        
        // Name it specifically so your detection logic works later
        // e.g. "https_google_com.txt" or "My_Note.txt"
        let safeName = text.prefix(20).replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "")
        let fileName = isLink ? "Link_\(safeName).txt" : "Note_\(safeName).txt"
        
        let tempFileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try text.write(to: tempFileURL, atomically: true, encoding: .utf8)
            filesToSave.append(tempFileURL)
            UploadedContent.reloadData()
        } catch {
            print("❌ Failed to create temp file: \(error)")
        }
    }
    
    // MARK: - Actions
    @IBAction func DoneTapped(_ sender: Any) {
        // Go to Select Material screen
        performSegue(withIdentifier: "showSelectMaterial", sender: nil)
    }
    
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
    
    // MARK: - Helper Methods
    private func openDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .plainText, .image], asCopy: true)
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
                self.processTextOrLinkInput(text: text)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - UITableView Data Source (Your Custom Card Style)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesToSave.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: confirmationCellID, for: indexPath)
        let url = filesToSave[indexPath.row]
        let fileName = url.lastPathComponent
        
        // --- 1. DETERMINE FILE TYPE ---
        let lowerName = fileName.lowercased()
        var detectedType = "text"
        
        if lowerName.hasSuffix("pdf") {
            detectedType = "pdf document"
        }
        // Logic modified slightly to catch the temp files we created (Link_...)
        else if lowerName.contains("http") || lowerName.contains("www.") || lowerName.contains("link_") {
            detectedType = "web link"
        }
        // Logic to catch Images
        else if lowerName == "media asset" || lowerName.hasSuffix("jpg") || lowerName.hasSuffix("png") || lowerName.contains("image_") {
            detectedType = "photo/video"
        }
        
        // --- 2. RESTORED SWITCH LOGIC (Your Colors/Icons) ---
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
        
        // --- 3. CARD STYLING (Your Exact Layout) ---
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
        icon.image = UIImage(systemName: symbolName)
        icon.tintColor = tintColor
        icon.contentMode = .scaleAspectFit
        
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Label (Clean up display name if it's a temp file)
        let label = UILabel()
        var displayName = fileName
        if displayName.starts(with: "Link_") { displayName = "Web Link" }
        if displayName.starts(with: "Note_") { displayName = "Text Note" }
        if displayName.starts(with: "Image_") { displayName = "Media Asset" }
        
        label.text = displayName
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
        if segue.identifier == "showSelectMaterial" {
            if let destVC = segue.destination as? SelectMaterialViewController {
                // Pass the files safely to the next screen
                destVC.filesToSave = self.filesToSave
            }
        }
    }
}

// MARK: - Delegates
extension UploadConfirmationViewController: UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            // Copy to temp to ensure we have access rights later
            let tempDir = FileManager.default.temporaryDirectory
            let destURL = tempDir.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: destURL)
            
            filesToSave.append(destURL)
            UploadedContent.reloadData()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 0.8) else { return }
            
            // Save to temp file so it flows through the same logic
            let filename = "Image_\(Int(Date().timeIntervalSince1970)).jpg"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            
            try? data.write(to: tempURL)
            self.filesToSave.append(tempURL)
            self.UploadedContent.reloadData()
        }
    }
}
