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
        
        
        studyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "StudyCell")
        
        if #available(iOS 11.0, *) {
            studyTableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDataUpdate),
                                               name: .didUpdateStudyMaterials,
                                               object: nil)
       

        setupConstraints()
        fetchFolderNames()
    }
    @objc func handleDataUpdate() {
        
        fetchFolderNames()
        
        studyTableView.reloadData()
    }
    
    
  

    
    
    // MARK: - Navigation Data Transfer
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(refreshFolderList),
            name: .didUpdateStudyFolders,
            object: nil)
        
       
        fetchFolderNames()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
        NotificationCenter.default.removeObserver(self,
            name: .didUpdateStudyMaterials,
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
        
        fetchFolderNames()
        
    }
    
    // MARK: - UITableViewDataSource
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subjectNames.count
    }

    
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
                    
                   
                    NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
                    
                    
                    
                    self.fetchFolderNames()
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
        
        
        cell.textLabel?.text = subjectNames[indexPath.row]
        cell.imageView?.image = UIImage(systemName: "folder")
        cell.imageView?.tintColor = UIColor.systemBlue
        
        
        cell.accessoryType = .disclosureIndicator
        
        
        cell.selectionStyle = .default
        
        
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
        
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            
            guard let self = self else {
                completionHandler(false)
                return
            }
            
           
            let alert = UIAlertController(
                title: "Delete '\(subjectToDelete)'?",
                message: "Are you sure you want to permanently delete this subject and all its materials?",
                preferredStyle: .alert
            )
            
           
            let confirmAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                
                
                self.executeDeletion(at: indexPath)
                
                
                completionHandler(true)
            }
            
           
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                
                completionHandler(false)
            }
            
            alert.addAction(cancelAction)
            alert.addAction(confirmAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
       
        configuration.performsFirstActionWithFullSwipe = true
        
        return configuration
    }
    func executeDeletion(at indexPath: IndexPath) {
    let subjectToDelete = self.subjectNames[indexPath.row]
        
        // 1. Tell DataManager to delete it from the actual JSON file on disk
        DataManager.shared.deleteSubjectFolder(name: subjectToDelete)
        
        // 2. Remove it from the local list so it disappears from the screen
//        self.subjectNames.remove(at: indexPath.row)
//        
//        // 3. Animate the deletion in the table
//        self.studyTableView.deleteRows(at: [indexPath], with: .fade)
        
        print("Subject deleted from disk and UI: \(subjectToDelete)")
    }
        
    // MARK: - UITableViewDelegate (Accessory / Segue)

    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedSubjectName = subjectNames[indexPath.row]
        
       
        performSegue(withIdentifier: "ShowSubjectDetailProgrammatic", sender: selectedSubjectName)
    }
}
