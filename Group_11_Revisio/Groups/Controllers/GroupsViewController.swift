//
//  GroupsViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 26/11/25.
//

import UIKit

class GroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, JoinGroupDelegate, GroupUpdateDelegate, UISearchResultsUpdating {
    
    @IBOutlet weak var groupsTableView: UITableView!
    
    //Dummy Data
    var myGroups: [Group] = [
        Group(name: "iMAAC", avatarName: "gpfp1"),
        Group(name: "Study Squad", avatarName: "gpfp2"),
        Group(name: "Project Phoenix", avatarName: "gpfp3"),
        Group(name: "Late Night Coders", avatarName: "gpfp4"),
        Group(name: "Math Wizards", avatarName: "gpfp5"),
        Group(name: "Swift Masters", avatarName: "gpfp6"),
        Group(name: "Exam Prep", avatarName: "gpfp7"),
        Group(name: "Final Year Crew", avatarName: "gpfp8"),
        Group(name: "Deep Learners", avatarName: "gpfp9"),
        Group(name: "AI Enthusiasts", avatarName: "gpfp10")
    ]
    
    private let groupAvatars = [
        "gpfp1","gpfp2","gpfp3","gpfp4","gpfp5",
        "gpfp6","gpfp7","gpfp8","gpfp9","gpfp10"
    ]
    
    private let sampleLastMessages: [String] = [
        "Did you upload the notes?",
        "Deadline is tomorrow",
        "Let’s meet after class",
        "I pushed the final changes",
        "Check the PDF I sent",
        "Any update on this?",
        "We’ll discuss this later",
        "Did you submit the test?",
        "Can someone explain Q3?",
        "Meeting at 6?"
    ]
    
    private let joinCodeMap: [String: String] = [
        "IMA-123": "iMAAC"
    ]
    
    //Search bar
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredGroups: [Group] = []
    private var isSearching: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Groups"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        groupsTableView.dataSource = self
        groupsTableView.delegate = self
        groupsTableView.tableFooterView = UIView()
        
        //Search
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Groups"

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        definesPresentationContext = true
    }
    
    func didUpdateGroup(_ group: Group) {

        if let index = myGroups.firstIndex(where: { $0.name == group.name }) {
            myGroups[index] = group

            let indexPath = IndexPath(row: index, section: 0)
            groupsTableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    // 1. Returns the total count of groups
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredGroups.count : myGroups.count
    }
    
    // 2. Creates and configures each cell (row)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Dequeue the cell and cast it to the custom GroupCell class
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCellIdentifier", for: indexPath) as? GroupCell else {
            return UITableViewCell()
        }
        
        let group = isSearching
            ? filteredGroups[indexPath.row]
            : myGroups[indexPath.row]
        cell.groupNameLabel.text = group.name
        cell.groupNameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)

        // Subtitle (fake last message for aesthetics)
        let messageIndex = indexPath.row % sampleLastMessages.count
        cell.lastMessageLabel.text = sampleLastMessages[messageIndex]
        cell.lastMessageLabel.textColor = .secondaryLabel
        cell.lastMessageLabel.font = UIFont.systemFont(ofSize: 14)

        //Avatars
        cell.configureAvatar(group.avatarName)
        
        cell.avatarImageView.layer.cornerRadius = 22
        cell.avatarImageView.clipsToBounds = true

        return cell

    }
    
    // 3. Set the height for each row
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
    }
    
    // Allow editing (necessary for older commit-style deletion)
        func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
    // Modern swipe actions (preferred). Provides the red "Delete" swipe button.
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { completion(false); return }
            self.confirmDelete(at: indexPath) { didDelete in
                completion(didDelete)
            }
        }
        
        // You can add other actions (edit, favorite) by creating more UIContextualAction objects
        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        config.performsFirstActionWithFullSwipe = true // allow full swipe to delete
        return config
    }
    
    // MARK: - Group Chat
    // add this inside your GroupsViewController class (below existing table methods)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let storyboard = UIStoryboard(name: "Groups", bundle: nil)

            guard let chatVC = storyboard.instantiateViewController(
                withIdentifier: "ChatVC"
            ) as? ChatViewController else {
                return
            }
        let selectedGroup = isSearching
            ? filteredGroups[indexPath.row]
            : myGroups[indexPath.row]

        chatVC.group = selectedGroup

            navigationController?.pushViewController(chatVC, animated: true)
    }
    
    // MARK: - Delete helper
        
    private func confirmDelete(at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let group = myGroups[indexPath.row]
        let alert = UIAlertController(title: "Delete Group", message: "Are you sure you want to delete \"\(group.name)\"?",preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completion(false)
            })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self = self else { completion(false); return }
                
                // 1) Update your model
                self.myGroups.remove(at: indexPath.row)
                
                // 2) Update persistent storage if needed
                // e.g. call your backend or delete from CoreData here
                // self.deleteGroupFromServer(group)
                
                // 3) Update the table view with animation
                self.groupsTableView.beginUpdates()
                self.groupsTableView.deleteRows(at: [indexPath], with: .automatic)
                self.groupsTableView.endUpdates()
                
                completion(true)
            })
            present(alert, animated: true, completion: nil)
        }
    
    @IBAction func joinGroupButtonTapped(_ sender: UIButton) {

        let storyboard = UIStoryboard(name: "Groups", bundle: nil)

        guard let joinVC = storyboard.instantiateViewController(
            withIdentifier: "JoinGroupVC"
        ) as? JoinGroupViewController else {
            print("JoinGroupViewController not found")
            return
        }
        joinVC.delegate = self

        let nav = UINavigationController(rootViewController: joinVC)
        present(nav, animated: true)
    }
    
    @IBAction func createGroupButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Groups", bundle: nil)
        guard let createNav = storyboard.instantiateViewController(withIdentifier: "CreateNavVC") as? UINavigationController else {
                print("ERROR: Could not instantiate CreateNavVC")
                return
            }
        
        // IMPORTANT: Find the CreateGroupViewController inside the nav stack
            if let createVC = createNav.viewControllers.first(where: { $0 is CreateGroupViewController }) as? CreateGroupViewController {
                createVC.delegate = self
            } else {
                print("WARNING: CreateGroupViewController not found inside CreateNavVC")
            }
        
            createNav.modalPresentationStyle = .pageSheet
            present(createNav, animated: true)
    }
    
    func didJoinGroup(groupName: String) {

        // 1. Find existing group (iMAAC)
        guard let group = myGroups.first(where: { $0.name == groupName }) else {
            print("Group not found:", groupName)
            return
        }

        // 2. Open ChatVC for that group
        let storyboard = UIStoryboard(name: "Groups", bundle: nil)
        guard let chatVC = storyboard.instantiateViewController(
            withIdentifier: "ChatVC"
        ) as? ChatViewController else {
            return
        }

        chatVC.group = group
        chatVC.updateDelegate = self
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text?.lowercased() ?? ""

        if searchText.isEmpty {
            isSearching = false
            filteredGroups.removeAll()
        } else {
            isSearching = true
            filteredGroups = myGroups.filter {
                $0.name.lowercased().contains(searchText)
            }
        }

        groupsTableView.reloadData()
    }
}


// MARK: - CreateGroupDelegate
extension GroupsViewController: CreateGroupDelegate {
    func didCreateGroup(_ group: Group) {

        // 1. Insert new group at the top of your data source
        myGroups.insert(group, at: 0)

        // 2. Animate insertion of the first row
        groupsTableView.beginUpdates()
        groupsTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        groupsTableView.endUpdates()

        // 3. Scroll so the user sees the newly added group
        groupsTableView.scrollToRow(at: IndexPath(row: 0, section: 0),
                                    at: .top,
                                    animated: true)
    }
}
extension GroupsViewController: LeaveGroupDelegate {
    func didLeaveGroup(_ group: Group) {
        if let idx = myGroups.firstIndex(where: { $0.name == group.name }) {
            myGroups.remove(at: idx)
            
            groupsTableView.beginUpdates()
            groupsTableView.deleteRows(
                at: [IndexPath(row: idx, section: 0)],
                with: .automatic
            )
            groupsTableView.endUpdates()
        }
    }
}
