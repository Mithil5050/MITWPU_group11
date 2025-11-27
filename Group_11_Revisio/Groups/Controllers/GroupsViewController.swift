//
//  GroupsViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 26/11/25.
//

import UIKit

class GroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var groupsTableView: UITableView!
    
    let myGroups: [Group] = [
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
}

