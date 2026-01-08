//
//  UploadConfirmationViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 26/11/25.
//

import UIKit
import UniformTypeIdentifiers // Required for Document Picker

class UploadConfirmationViewController: UIViewController {
    
    // MARK: - Properties
    var uploadedContentName: String?
    var uploadedMaterials: [StudyContent] = []
    var parentSubjectName: String?
    
    // Header Label
//    private let sourceHeaderLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
//        label.textColor = .secondaryLabel
//        return label
//    }()
    
    // MARK: - IBOutlets
    @IBOutlet var UploadedContent: UITableView!
    @IBOutlet var doneButton: UIButton!
    
    // ⭐️ NEW: Outlet for the Plus Button in your Navigation Bar or UI
    // Make sure to connect this in Storyboard if it's a UIBarButtonItem
    @IBOutlet weak var addButton: UIButton!
    
    private let confirmationCellID = "ConfirmationContentCell"
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Upload Confirmed"
        
        setupUI()
        setupTable()
//        setupDoneButton()
        
        // Load Data
        refreshData()
    }
    
    private func refreshData() {
        self.uploadedMaterials = JSONDatabaseManager.shared.loadFiles()
//        sourceHeaderLabel.text = "Materials from: \(uploadedContentName ?? "Recent Uploads")"
        UploadedContent?.reloadData()
    }
    
    // MARK: - ⭐️ NEW: Add Button Logic (The Action Sheet)
    
    // CONNECT THIS ACTION TO YOUR + BUTTON IN STORYBOARD
    @IBAction func didTapAddButton(_ sender: Any) {
        let alert = UIAlertController(title: "Add Material", message: "Choose a source", preferredStyle: .actionSheet)
        
        // Option 1: Document
        alert.addAction(UIAlertAction(title: "Document", style: .default, handler: { _ in
            self.openDocumentPicker()
        }))
        
        // Option 2: Photo/Media
        alert.addAction(UIAlertAction(title: "Photo / Media", style: .default, handler: { _ in
            self.openPhotoPicker()
        }))
        
        // Option 3: Link
        alert.addAction(UIAlertAction(title: "Web Link", style: .default, handler: { _ in
            self.showTextInput(title: "Add Web Link", placeholder: "https://example.com")
        }))
        
        // Option 4: Text
        alert.addAction(UIAlertAction(title: "Text Note", style: .default, handler: { _ in
            self.showTextInput(title: "Add Quick Note", placeholder: "Enter note title...")
        }))
        
        // Cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                // This specific line forces the text color to Red
                cancelAction.setValue(UIColor.systemRed, forKey: "titleTextColor")
                alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Helper Functions for Input
    
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
    
    /// Central function to save data and update UI
    private func processNewUpload(name: String) {
        // 1. Save to Database
        JSONDatabaseManager.shared.addUploadedFile(name: name)
        
        // 2. Refresh local data and table
        refreshData()
        
        // 3. Scroll to bottom (optional UI polish)
        if !uploadedMaterials.isEmpty {
            let indexPath = IndexPath(row: uploadedMaterials.count - 1, section: 0)
            UploadedContent.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    // MARK: - Setup UI (Existing Code)
    private func setupUI() {
        let guide = view.safeAreaLayoutGuide
//        view.addSubview(sourceHeaderLabel)
        
        if let table = UploadedContent {
            table.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
//                sourceHeaderLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 20),
//                sourceHeaderLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
//                sourceHeaderLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
                
//                table.topAnchor.constraint(equalTo: sourceHeaderLabel.bottomAnchor, constant: 8),
                table.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
                table.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
                table.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -100)
            ])
        }
    }
    
    private func setupTable() {
        guard let table = UploadedContent else { return }
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: confirmationCellID)
        table.separatorStyle = .none
        table.backgroundColor = .systemBackground
        table.layer.cornerRadius = 12.0
        table.clipsToBounds = true
    }
    
//    private func setupDoneButton() {
//        guard let btn = doneButton else { return }
//        var config = UIButton.Configuration.filled()
//        config.cornerStyle = .capsule
//        config.baseBackgroundColor = .systemBlue
//        config.baseForegroundColor = .white
//        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
//            var outgoing = incoming
//            outgoing.font = UIFont.systemFont(ofSize: 17, weight: .bold)
//            return outgoing
//        }
//        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
//        btn.configuration = config
//        
//        btn.layer.shadowColor = UIColor.black.cgColor
//        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
//        btn.layer.shadowRadius = 8
//        btn.layer.shadowOpacity = 0.15
//        btn.layer.masksToBounds = false
//    }
    
    @IBAction func DoneTapped(_ sender: Any) {
        performSegue(withIdentifier: "showGenerationScreenHome", sender: uploadedMaterials)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGenerationScreenHome" {
            if let destinationVC = segue.destination as? GenerateHomeViewController {
                destinationVC.inputSourceData = sender as? [StudyContent]
                destinationVC.contextSubjectTitle = self.parentSubjectName
            }
        }
    }
}

// MARK: - Table View Data Source & Delegate (Existing)
extension UploadConfirmationViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uploadedMaterials.count
    }
    
    private func derivedDisplay(for item: StudyContent) -> (title: String, type: String) {
        let title = item.filename.isEmpty ? "Untitled Content" : item.filename
        var type = "Text Input"
        if title.lowercased().hasSuffix(".pdf") { type = "PDF Document" }
        else if title.lowercased().contains("http") { type = "Web Link" }
        else if title == "Media Asset" { type = "Photo/Video" }
        return (title, type)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: confirmationCellID, for: indexPath)
        let item = uploadedMaterials[indexPath.row]
        let display = derivedDisplay(for: item)
        
        var content = cell.defaultContentConfiguration()
        content.text = display.title
        content.secondaryText = display.type
        
        let symbolName: String
        let tintColor: UIColor
        
        switch display.type.lowercased() {
        case "pdf document":
            symbolName = "doc.fill"
            tintColor = .systemRed
        case "web link":
            symbolName = "link"
            tintColor = .systemBlue
        case "photo/video":
            symbolName = "photo"
            tintColor = .systemPurple
        default:
            symbolName = "text.justify.left"
            tintColor = .systemGray
        }
        
        content.image = UIImage(systemName: symbolName)
        content.imageProperties.tintColor = tintColor
        
        cell.contentConfiguration = content
        cell.backgroundColor = .systemGray6
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { return true }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            JSONDatabaseManager.shared.deleteFile(at: indexPath.row)
            uploadedMaterials.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - ⭐️ NEW: Picker Delegates
extension UploadConfirmationViewController: UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            processNewUpload(name: url.lastPathComponent)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            // You could handle actual image data here, but for now we just log the name
            self.processNewUpload(name: "Media Asset")
        }
    }
}
