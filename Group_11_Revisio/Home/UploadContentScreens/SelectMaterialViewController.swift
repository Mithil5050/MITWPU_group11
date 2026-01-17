//
//  SelectMaterialViewController.swift
//  MITWPU_group11
//
//  Created by Mithil on 08/01/26.
//

import UIKit

class SelectMaterialViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties
    var folders = [
        "Calculus",
        "Data Structures",
        "Big Data",
        "MMA",
        "Swift Fundamentals",
        "Computer Network"
    ]
    
    var selectedFolder: String?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - Actions
    @IBAction func doneTap(_ sender: UIButton) {
        guard selectedFolder != nil else {
            let alert = UIAlertController(title: "Selection Required", message: "Please select a folder to proceed.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        performSegue(withIdentifier: "showGeneration", sender: nil)
    }
    
    @IBAction func addFolderTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Folder", message: "Enter a name for this folder", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Folder Name"
            textField.autocapitalizationType = .words
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text,
                  !text.isEmpty else { return }
            self.createNewFolder(named: text)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(createAction)
        present(alert, animated: true)
    }
    
    func createNewFolder(named name: String) {
        folders.append(name)
        let newIndexPath = IndexPath(row: folders.count - 1, section: 0)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
        tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
    }

    // MARK: - Table View Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath)
        
        // 1. Content Configuration
        var content = cell.defaultContentConfiguration()
        content.text = folders[indexPath.row]
        content.image = UIImage(systemName: "folder")
        content.imageProperties.tintColor = .systemBlue
        cell.contentConfiguration = content
        
        // 2. Custom Selection Icon Logic [UPDATED]
        let isSelected = (folders[indexPath.row] == selectedFolder)
        
        // Choose the icon based on selection state
        let iconName = isSelected ? "checkmark.circle.fill" : "circle"
        let iconColor = isSelected ? UIColor.systemBlue : UIColor.systemGray3
        
        // Create a custom Image View for the accessory
        let iconImage = UIImage(systemName: iconName)
        let iconImageView = UIImageView(image: iconImage)
        iconImageView.tintColor = iconColor
        
        // Assign to accessoryView
        cell.accessoryView = iconImageView
        cell.accessoryType = .none // Ensure standard type doesn't override it
        
        return cell
    }
    
    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Update selection
        selectedFolder = folders[indexPath.row]
        
        // Reload to update the circles/ticks
        tableView.reloadData()
        
        print("Selected: \(selectedFolder ?? "None")")
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGeneration" {
            if let destVC = segue.destination as? GenerateHomeViewController {
                if let folder = selectedFolder {
                    destVC.inputSourceData = [folder]
                    destVC.contextSubjectTitle = folder
                }
            }
        }
    }
}
