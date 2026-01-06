//
//  GroupsViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 26/11/25.
//

import UIKit

class GroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, JoinGroupDelegate {
    
    @IBOutlet weak var groupsTableView: UITableView!
    
    var myGroups: [Group] = [
        Group(name: "iMAAC"),
        Group(name: "Group 2"),
        Group(name: "Group 3"),
        Group(name: "Group 4"),
        Group(name: "Group 5"),
        Group(name: "Group 6"),
        Group(name: "Group 7"),
        Group(name: "Group 8"),
        Group(name: "Group 9"),
        Group(name: "Group 10"),
    ]
    
    private let joinCodeMap: [String: String] = [
        "IMA-123": "iMAAC"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure the table view's data source and delegate are set
        // (If not done in Storyboard, this makes it functional)
        groupsTableView.dataSource = self
        groupsTableView.delegate = self
        // This removes the extra empty lines below the last group item
        groupsTableView.tableFooterView = UIView()
        
    }
    
    
    // 1. Returns the total count of groups
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myGroups.count
    }
    
    // 2. Creates and configures each cell (row)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Dequeue the cell and cast it to the custom GroupCell class
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCellIdentifier", for: indexPath) as? GroupCell else {
            return UITableViewCell()
        }
        
        // Get the correct Group object for the current row
        let group = myGroups[indexPath.row]
        // Set the text using the outlet you created in GroupCell
        cell.groupNameLabel.text = group.name
        // Set the accessory arrow
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    // 3. Set the height for each row
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
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
            chatVC.group = myGroups[indexPath.row]

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

        joinVC.delegate = self   // ✅ THIS WAS MISSING
        present(joinVC, animated: true)
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
        navigationController?.pushViewController(chatVC, animated: true)
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
