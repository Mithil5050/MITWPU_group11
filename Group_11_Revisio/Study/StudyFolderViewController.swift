//
//  StudyFolderViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import UIKit

class StudyFolderViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let studyTableView = UITableView(frame: .zero, style: .plain)
    private var subjectNames: [String] = [ "Calculus",
                                                  "Big Data",
                                                   "MMA",
                                                 "Swift Fundamentals",
                                                "Computer Networks"]
        
//    private let studyMaterials: [String] = [
//        "Calculus",
//        "Big Data",
//        "MMA",
//        "Swift Fundamentals",
//        "Computer Networks"
//    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()
            
        view.backgroundColor = .systemBackground
            
        view.addSubview(studyTableView)
            
        studyTableView.translatesAutoresizingMaskIntoConstraints = false
            
        studyTableView.dataSource = self
        studyTableView.delegate = self
            
        studyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "StudyCell")
            
        if #available(iOS 11.0, *) {
            studyTableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
            
        setupConstraints()
        fetchFolderNames()
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
            
            // REMOVE OBSERVER: Clean up when the view is dismissed
            NotificationCenter.default.removeObserver(self,
                name: .didUpdateStudyFolders,
                object: nil)
        }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSubjectDetailProgrammatic" {
            // NOTE: Assuming your detail view controller is named SubjectDetailViewController,
            // I've corrected SubjectViewController to the standard naming convention used earlier.
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
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StudyCell", for: indexPath)
            
        cell.textLabel?.text = subjectNames[indexPath.row]
        cell.imageView?.image = UIImage(systemName: "folder")
        cell.imageView?.tintColor = UIColor.systemBlue
        cell.accessoryType = .disclosureIndicator
            
        return cell
    }
        
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            // Using a plain style table view, this provides the "Your Materials" header
            return "Your Materials"
        }
        return nil
    }
    
    // StudyFolderViewController.swift

    func handleDeleteFolder(at indexPath: IndexPath) {
            
            // 1. Get the name needed for the DataManager update
            let subjectNameToDelete = self.subjectNames[indexPath.row]
            
            // 2. CRITICAL FIX: Remove the name from the local array FIRST.
            // This synchronizes the local data source count with the UI animation count.
            self.subjectNames.remove(at: indexPath.row)
            
            // 3. Animate the UI deletion. This must complete without interruptions.
            studyTableView.beginUpdates()
            studyTableView.deleteRows(at: [indexPath], with: .automatic)
            studyTableView.endUpdates()
            
            // 4. Update the DataManager LAST. This posts the notification, but the UI is already updated.
            DataManager.shared.deleteSubjectFolder(name: subjectNameToDelete)
        }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
                
                guard let self = self else {
                    completionHandler(false)
                    return
                }
                
                self.handleDeleteFolder(at: indexPath)
                completionHandler(true)
            }
            
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            configuration.performsFirstActionWithFullSwipe = true
            
            return configuration
        }
        
    // MARK: - UITableViewDelegate (Segue Trigger)
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect the row immediately for standard iOS behavior
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 1. Get the subject data for the selected row
        let selectedSubjectName = subjectNames[indexPath.row]
        
        // 2. Trigger the segue defined in the Storyboard
        performSegue(withIdentifier: "ShowSubjectDetailProgrammatic", sender: selectedSubjectName)
    }
  
}
