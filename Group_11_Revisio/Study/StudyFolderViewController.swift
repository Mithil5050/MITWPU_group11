//
//  StudyFolderViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import UIKit

class StudyFolderViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let studyTableView = UITableView(frame: .zero, style: .plain)
    private var subjectNames: [String] = [
        "Calculus",
        "Big Data",
        "MMA",
        "Swift Fundamentals",
        "Computer Networks"
    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        view.addSubview(studyTableView)
        
        studyTableView.translatesAutoresizingMaskIntoConstraints = false
        studyTableView.layer.cornerRadius = 12.0
        studyTableView.clipsToBounds = true
        
        studyTableView.dataSource = self
        studyTableView.delegate = self
        // studyTableView.allowsMultipleSelectionDuringEditing = false
        
        studyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "StudyCell")
        
        if #available(iOS 11.0, *) {
            studyTableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        // --- CRITICAL ADDITION: Setup Notification Observer ---
        // This listener ensures that when any subject is renamed/deleted elsewhere in the app,
        // this table view is notified to reload its data.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDataUpdate),
                                               name: .didUpdateStudyMaterials,
                                               object: nil)
        // --- END ADDITION ---

        setupConstraints()
        fetchFolderNames()
    }
    @objc func handleDataUpdate() {
        // Re-fetch the list of subject names from your data manager
        fetchFolderNames()
        // Reload the table view to display the updated names/list
        studyTableView.reloadData()
    }
    
    
  

    
    
    // MARK: - Navigation Data Transfer
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ADD OBSERVER: Listen for the signal that a new folder was created
        NotificationCenter.default.addObserver(self,
            selector: #selector(refreshFolderList),
            name: .didUpdateStudyFolders,
            object: nil)
        
        // Reload data just in case the view was pulled down and content changed
        fetchFolderNames()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Clean up the observer using the correct notification name for subject data updates.
        NotificationCenter.default.removeObserver(self,
            name: .didUpdateStudyMaterials, // Assuming this is the name used for renames/data changes
            object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSubjectDetailProgrammatic" {
            if let detailVC = segue.destination as? SubjectViewController {
                if let selectedSubject = sender as? String {
                    detailVC.selectedSubject = selectedSubject
                }
            }
        }
    }
    
    func fetchFolderNames() {
        // Fetch all current folder names (keys) from the DataManager
        self.subjectNames = Array(DataManager.shared.savedMaterials.keys).sorted()
        studyTableView.reloadData()
    }
        
    func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
            
        NSLayoutConstraint.activate([
            studyTableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            studyTableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            studyTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            studyTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc func refreshFolderList() {
        // This is called when the notification arrives from the CreateFolderViewController
        fetchFolderNames()
        // Reload is already included in fetchFolderNames(), but calling it here ensures the latest data.
    }
    
    // MARK: - UITableViewDataSource
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subjectNames.count
    }

    // Context menu for rows
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        let folderName = self.subjectNames[indexPath.row]
        let identifier = folderName as NSString
        
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }
            
            let shareFolderAction = UIAction(title: "Share Folder", image: UIImage(systemName: "person.crop.circle.badge.plus")) { _ in
                print("Action: Sharing folder \(folderName)")
            }
            
            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in
                
                self.presentRenameAlert(for: folderName) { newName in
                    
                    
                    DataManager.shared.renameSubject(oldName: folderName, newName: newName)
                    
                    // Post notification for other view controllers (like SubjectViewController) to update.
                    // This triggers the SubjectViewController to update its title and reload its content.
                    NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
                    
                    
                    // This ensures the new name appears instantly on the Study Folder screen.
                    self.fetchFolderNames() // Re-fetches the list of subjects from DataManager
                    tableView.reloadData()
                }
            }
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                print("Action: Deleting folder \(folderName)")
            }
            
            let primaryActions = UIMenu(title: "", options: .displayInline, children: [renameAction, shareFolderAction])
            let destructiveActions = UIMenu(title: "", options: .displayInline, children: [deleteAction])
            
            return UIMenu(title: "", children: [primaryActions, destructiveActions])
        }
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "StudyCell", for: indexPath)
        
        // Set the content: Folder name, icon, and color
        cell.textLabel?.text = subjectNames[indexPath.row]
        cell.imageView?.image = UIImage(systemName: "folder")
        cell.imageView?.tintColor = UIColor.systemBlue
        
        // Set the default accessory type for non-editing mode (the right arrow)
        cell.accessoryType = .disclosureIndicator
        
        // Ensure the selection style doesn't interfere
        cell.selectionStyle = .default
        
        // Note: Folder management actions (Rename/Share) are handled by the long-press Context Menu.
        
        return cell
    }
        
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Your Materials"
        }
        return nil
    }
    
    // MARK: - Delete Handling

   
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let subjectToDelete = self.subjectNames[indexPath.row]
        
        // 1. Define the Delete Action (This button appears after the swipe)
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            // 2. Present the Confirmation Alert
            let alert = UIAlertController(
                title: "Delete '\(subjectToDelete)'?",
                message: "Are you sure you want to permanently delete this subject and all its materials?",
                preferredStyle: .alert
            )
            
            // Action 3a: Confirmation (Execute Deletion)
            let confirmAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                
                // Execute the deletion logic (deletes from data and UI)
                self.executeDeletion(at: indexPath)
                
                // Indicate that the action was performed successfully
                completionHandler(true)
            }
            
            // Action 3b: Cancel (Do not delete, hide swipe button)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                // Indicate that the action was NOT performed (hides the swipe menu)
                completionHandler(false)
            }
            
            alert.addAction(cancelAction)
            alert.addAction(confirmAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        // You can set this to false if you don't want the full swipe to trigger the alert immediately
        configuration.performsFirstActionWithFullSwipe = true
        
        return configuration
    }
    func executeDeletion(at indexPath: IndexPath) {
        let subjectToDelete = self.subjectNames[indexPath.row]
        
        // 1. Data Logic: Delete the subject from your data manager
        // DataManager.shared.deleteSubject(name: subjectToDelete) // Assuming DataManager has this method
        
        // 2. UI Data Update: Remove the item from the local array
        self.subjectNames.remove(at: indexPath.row)
        
        // 3. UI Update: Animate the row deletion
        self.studyTableView.deleteRows(at: [indexPath], with: .fade)
        
        // 4. Notify other screens (like SubjectViewController) that the data has changed
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        
        print("Subject deleted: \(subjectToDelete)")
    }
        
    // MARK: - UITableViewDelegate (Accessory / Segue)

    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Deselect the row immediately to remove the highlight effect
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedSubjectName = subjectNames[indexPath.row]
        
        // Perform the segue to the SubjectViewController, passing the folder name
        performSegue(withIdentifier: "ShowSubjectDetailProgrammatic", sender: selectedSubjectName)
    }
}
