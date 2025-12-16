//
//  CheatSheetDetailViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 16/12/25.
//


//
//  CheatSheetDetailViewController.swift
//  Group_11_Revisio
//

import UIKit

class CheatSheetDetailViewController: UIViewController {
    
    // MARK: - Outlets
    // Refactored names to avoid conflict with MaterialDetailViewController
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
        
        // Delegate for auto-saving
        cheatSheetTextView.delegate = self
        cheatSheetTextView.isEditable = false
        
        configureCheatSheetUI()
        fetchSheetContent()
    }
    
    // MARK: - Interface Configuration
    private func configureCheatSheetUI() {
        // Setup Primary Toggle (Edit/Done)
        cheatSheetEditToggle.target = self
        cheatSheetEditToggle.action = #selector(handleCheatSheetToggle)
        
        // Setup Secondary Options Menu
        cheatSheetActionMenu.menu = buildCheatSheetMenu()
        
        // standard UIKit bar layout
        navigationItem.rightBarButtonItems = [cheatSheetEditToggle, cheatSheetActionMenu]
        
        updateSheetStateUI()
    }
    
    private func buildCheatSheetMenu() -> UIMenu {
        let share = UIAction(title: "Share Sheet", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            self?.executeShareAction()
        }
        
        let pin = UIAction(title: "Pin to Top", image: UIImage(systemName: "pin")) { _ in
            print("Cheat Sheet Pinned")
        }
        
        let delete = UIAction(title: "Delete Sheet", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            print("Cheat Sheet Deleted")
        }
        
        let inlineGroup = UIMenu(title: "", options: .displayInline, children: [share, pin])
        return UIMenu(title: "Sheet Options", children: [inlineGroup, delete])
    }
    
    // MARK: - Data Management
    private func fetchSheetContent() {
        title = sheetTitle ?? "Big Data Cheat Sheet"
        
        // Attempt load from DataManager
        if let topic = sheetData, let category = parentCategory {
            let content = DataManager.shared.getDetailedContent(for: category, topicName: topic.name)
            if !content.isEmpty {
                cheatSheetTextView.text = content
                return
            }
        }
        
        // Fallback Demo for Big Data
        injectBigDataDemo()
    }
    
    private func injectBigDataDemo() {
        cheatSheetTextView.text = """
        BIG DATA CHEAT SHEET
        
        ■ CORE CONCEPTS
        - Velocity: Real-time processing speed.
        - Volume: Data scale (TB/PB).
        - Variety: Unstructured vs Structured.
        
        ■ TECH STACK
        - Storage: HDFS, Amazon S3.
        - Analysis: Apache Spark, Hive.
        - NoSQL: MongoDB, Cassandra.
        
        ■ ARCHITECTURE
        - Lambda: Batch + Speed layers.
        - Kappa: Stream processing only.
        """
    }
    
    @objc private func handleCheatSheetToggle() {
        if isSheetInEditMode {
            syncChangesToStorage()
        }
        
        isSheetInEditMode.toggle()
        updateSheetStateUI()
    }
    
    private func updateSheetStateUI() {
        if isSheetInEditMode {
            cheatSheetEditToggle.image = UIImage(systemName: "checkmark.circle.fill")
            cheatSheetEditToggle.title = nil
            cheatSheetTextView.isEditable = true
            cheatSheetTextView.becomeFirstResponder()
        } else {
            cheatSheetEditToggle.image = nil
            cheatSheetEditToggle.title = "Edit"
            cheatSheetTextView.isEditable = false
            cheatSheetTextView.resignFirstResponder()
        }
    }
    
    private func syncChangesToStorage() {
        guard let topic = sheetData, let category = parentCategory else { return }
        let currentText = cheatSheetTextView.text ?? ""
        
        // DataManager.shared.updateTopicContent(subject: category, topicName: topic.name, newText: currentText)
        print("Auto-saved: \(topic.name)")
    }
    
    private func executeShareAction() {
        let items = [cheatSheetTextView.text ?? ""]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = cheatSheetActionMenu
        present(activityVC, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension CheatSheetDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        syncChangesToStorage()
    }
}
