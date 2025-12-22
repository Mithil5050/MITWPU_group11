//
//  UploadConfirmationViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 26/11/25.
//

import UIKit

// NOTE: Data Models (StudyContent, Topic) must be defined in a shared file (e.g., AppModels.swift).

class UploadConfirmationViewController: UIViewController {
    
    // ... (Existing properties)
    var uploadedContentName: String?
    var uploadedMaterials: [StudyContent] = []
    var parentSubjectName: String?
    
    // ⭐️ NEW: Label to act as the section header/source label
    private let sourceHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .secondaryLabel // Subdued gray color for headers
        return label
    }()
    
    // Table View Outlet (Connected from Storyboard)
    @IBOutlet var UploadedContent: UITableView!
    
    // Cell Identifier (Should match the registered or Storyboard cell)
    private let confirmationCellID = "ConfirmationContentCell"
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Upload Confirmed"
        
        setupDemoSources()
        setupUI()
        setupTable()
        updateUI()
    }
    
    // MARK: - Setup and Data
    
    private func setupDemoSources() {
        
        uploadedMaterials = [
             StudyContent(text: "Original Source Document (PDF)"),
             StudyContent(text: "Core Definitions and Concepts (Link)"),
            
        ]
    }
    
    private func setupUI() {
        let guide = view.safeAreaLayoutGuide // Use safe area for modern layout
        
        // ⭐️ ADDING NEW LABEL TO VIEW
        view.addSubview(sourceHeaderLabel)
        
        // 🚨 UNCOMMENTING AND ACTIVATING CONSTRAINTS: Anchor the label and the table
        if let table = UploadedContent {
            table.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                
                // 1. Anchor the Source Header Label below the top safe area
                sourceHeaderLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 20),
                sourceHeaderLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
                sourceHeaderLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
                
                // 2. Anchor the Table View right below the Source Header Label
                table.topAnchor.constraint(equalTo: sourceHeaderLabel.bottomAnchor, constant: 8), // Small gap
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
    
    private func updateUI() {
        // Updated text to reflect the source content context
//        sourceHeaderLabel.text = "Materials from: \(uploadedContentName ?? "Source Documents")"
//        
//        UploadedContent?.reloadData()
    }
    
    // MARK: - Action Handlers
    
    @IBAction func DoneTapped(_ sender: Any) {
        performSegue(withIdentifier: "showGenerationScreenHome", sender: uploadedMaterials)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGenerationScreenHome" {
            if let destinationVC = segue.destination as? GenerateHomeViewController {
                destinationVC.inputSourceData = sender as? [StudyContent]
                // FIX: Use existing subject property to set the context title
                destinationVC.contextSubjectTitle = self.parentSubjectName
            }
        }
    }
}

// MARK: - Table View Data Source and Delegate

extension UploadConfirmationViewController: UITableViewDataSource, UITableViewDelegate {
    
    // Keeps the table header removed, as the sourceHeaderLabel handles the title.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Ensure count is based on actual data
        return uploadedMaterials.count
    }
    
    // Helper function to map generic content to specific display names/types
    private func derivedDisplay(for item: StudyContent) -> (title: String, type: String) {
         let index = uploadedMaterials.firstIndex(where: { $0.id == item.id }) ?? 0
         switch index {
         case 0:
             return ("Big Data Fundamentals", "PDF Document")
         case 1:
             return ("Core Data Science Concepts", "Web Link")
         default:
             // Fallback logic
             return (item.filename.isEmpty ? "Untitled Content" : item.filename, "Text Input")
         }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: confirmationCellID, for: indexPath)
        let item = uploadedMaterials[indexPath.row]
        
        let display = derivedDisplay(for: item)
        
        // Use defaultContentConfiguration for modern iOS cell style
        var content = cell.defaultContentConfiguration()
        content.text = display.title
        content.secondaryText = display.type
        
        // Derive a modern system icon (SFSymbol) based on fileType
        let symbolName: String
        let tintColor: UIColor
        switch display.type.lowercased() {
        case "pdf document":
            symbolName = "doc.fill"
            tintColor = .systemRed
        case "web link":
            symbolName = "link"
            tintColor = .systemBlue
        case "text input":
            symbolName = "textformat"
            tintColor = .systemGray
        default:
            symbolName = "questionmark.document.fill"
            tintColor = .systemGray
        }
        
        content.image = UIImage(systemName: symbolName)
        content.textProperties.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 14)
        content.imageProperties.tintColor = tintColor
        
        // Use the cell's background for a distinct list item look (iOS 26 aesthetic)
        cell.backgroundColor = .systemGray6
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let display = derivedDisplay(for: uploadedMaterials[indexPath.row])
        print("Tapped to view \(display.title)")
    }
}
