//
//  SelectMaterialViewController.swift
//  MITWPU_group11
//
//  Created by Mithil on 08/01/26.
//

import UIKit

class SelectMaterialViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets
    // ⚠️ IMPORTANT: Ensure this is connected to the Table View in Storyboard
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties
    // Use 'var' so we can append new folders to it
    var folders = [
        "Calculus",
        "Data Structures",
        "Big Data",
        "MMA",
        "Swift Fundamentals",
        "Computer Network"
    ]
    
    // Tracks the currently selected folder
    var selectedFolder: String?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        // Cosmetic: Remove empty cell lines at the bottom of the list
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - Actions
    
    // 1. Action for the "Done" button at the bottom
    @IBAction func doneTap(_ sender: UIButton) {
        // Validation: Ensure a user has actually selected a folder
        guard selectedFolder != nil else {
            let alert = UIAlertController(title: "Selection Required", message: "Please select a folder to proceed.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // If valid, move to the next screen
        performSegue(withIdentifier: "showGeneration", sender: nil)
    }
    
    // 2. Action for the "+" Bar Button Item in the top right
    @IBAction func addFolderTapped(_ sender: UIBarButtonItem) {
        // Create the popup
        let alert = UIAlertController(title: "New Folder", message: "Enter a name for this folder", preferredStyle: .alert)
        
        // Add text field
        alert.addTextField { textField in
            textField.placeholder = "Folder Name"
            textField.autocapitalizationType = .words
        }
        
        // "Create" button logic
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text,
                  !text.isEmpty else { return }
            
            self.createNewFolder(named: text)
        }
        
        // "Cancel" button
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(createAction)
        
        present(alert, animated: true)
    }
    
    // Helper function to update data and UI
    func createNewFolder(named name: String) {
        // Update Data Source
        folders.append(name)
        
        // Update Table View with Animation
        let newIndexPath = IndexPath(row: folders.count - 1, section: 0)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
        
        // Scroll to the new item
        tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
    }

    // MARK: - Table View Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // ⚠️ IMPORTANT: Ensure your Prototype Cell Identifier in Storyboard is "FolderCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath)
        
        // Modern Configuration (iOS 14+)
        var content = cell.defaultContentConfiguration()
        content.text = folders[indexPath.row]
        content.image = UIImage(systemName: "folder") // SF Symbol
        content.imageProperties.tintColor = .systemBlue
        
        cell.contentConfiguration = content
        
        // Toggle checkmark based on selection
        if folders[indexPath.row] == selectedFolder {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .disclosureIndicator // Or .none
        }
        
        return cell
    }
    
    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect the row visually
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Update the selected variable
        selectedFolder = folders[indexPath.row]
        
        // Reload table to update the checkmarks
        tableView.reloadData()
        
        print("Selected: \(selectedFolder ?? "None")")
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGeneration" {
            // Pass data to the next controller if needed
            // let destVC = segue.destination as? GenerationViewController
            // destVC?.folderName = selectedFolder
        }
    }
}
