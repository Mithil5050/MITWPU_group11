//
//  GroupSettingsViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 12/12/25.
//

import UIKit

class GroupSettingsViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var docsView: UIView!
    @IBOutlet weak var leaderboardView: UIView!

    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var membersCountLabel: UILabel!

    @IBOutlet weak var membersCollectionView: UICollectionView!
    
    @IBOutlet weak var docsCollectionView: UICollectionView!

    @IBOutlet weak var leaderboardTableView: UITableView!

    // Data
    var group: Group!
    weak var delegate: LeaveGroupDelegate?

    private let members: [(name: String, avatar: String)] = [
        ("You", "pfp_chirag"),
        ("Ashika", "pfp_ashika"),
        ("Mithil", "pfp_mithil"),
        ("Ayaana", "pfp_ayaana"),
        ("Tirthraj", "pfp_chirag"),
        ("Yash", "pfp_mithil"),
        ("Kavindra", "pfp_chirag"),
        ("Prachi", "pfp_ashika"),
        ("Smera", "pfp_ayaana")
    ]
    
    private var documents: [String] = ["DBMS.pdf","Statistics.pdf","DS QB.jpg","DETT.pdf","Operating systems.jpg"]
    private var leaderboard: [(name: String, score: Int)] = [("Chirag",650),("Ashika",590),("Ayaana",400)]

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.selectedSegmentIndex = 0
        showSegment(index: 0)
        
        // Header content
        groupNameLabel.text = group?.name ?? "Group"

        membersCountLabel.text = "\(members.count) members"
        
        groupImageView.image = UIImage(systemName: "person.3.fill")
        groupImageView.tintColor = .white
        
        // Navigation bar edit button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editGroupTapped)
        )

        docsCollectionView.dataSource = self
        docsCollectionView.delegate = self
        membersCollectionView.dataSource = self
        membersCollectionView.delegate = self
        leaderboardTableView.dataSource = self
        leaderboardTableView.delegate = self
    }
    
    @objc private func editGroupTapped() {
        print("Edit group tapped")
        // Later: push EditGroup screen
    }

    // MARK: - Segment control
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        showSegment(index: sender.selectedSegmentIndex)
    }

    private func showSegment(index: Int) {
        UIView.animate(withDuration: 0.2) {
            self.infoView.isHidden = index != 0
            self.docsView.isHidden = index != 1
            self.leaderboardView.isHidden = index != 2
        }
    }

    //MARK: - Hide Alerts
    @IBOutlet weak var hideAlertsSwitch: UISwitch!
    // MARK: - Leave group
    @IBAction func leaveButtonTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Leave Group", message: "Are you sure you want to leave this group?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Leave", style: .destructive, handler: { _ in
            self.performLeave()
        }))
        present(ac, animated: true)
    }

    private func performLeave() {
        guard let group = self.group else {
            navigationController?.popToRootViewController(animated: true)
            return
        }
        delegate?.didLeaveGroup(group)
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Edit group action (optional)
    @IBAction func editButtonTapped(_ sender: UIButton) {
        // placeholder: push edit UI later
        print("Edit tapped")
    }
}

// MARK: - Documents, Members Collection View
extension GroupSettingsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {

        if collectionView == membersCollectionView {
            return members.count + 1
        } else {
            return documents.count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView == membersCollectionView {

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "MemberCellIdentifier",
                for: indexPath
            ) as! MemberCell

            
        // LAST CELL → Add Member (+)
            if indexPath.item == members.count {
                cell.nameLabel.text = "Add Members"
                cell.nameLabel.text = "Add"
                cell.avatarImageView.image = UIImage(systemName: "plus.circle.fill")
                cell.avatarImageView.tintColor = .systemGray4
                cell.avatarImageView.backgroundColor = .clear
                return cell
            }
            
            let member = members[indexPath.item]
            cell.configure(name: member.name)
            cell.avatarImageView.image = UIImage(named: member.avatar)
            return cell

        } else {

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "DocumentCellIdentifier",
                for: indexPath
            ) as! DocumentCell

            cell.configure(title: documents[indexPath.item])
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        
        // Only react for Members collection
        guard collectionView == membersCollectionView else { return }

        // LAST CELL → Add Member (+)
        if indexPath.item == members.count {

            let storyboard = UIStoryboard(name: "Groups", bundle: nil)
            
            guard let codeVC = storyboard.instantiateViewController(
                withIdentifier: "GroupCodeVC"
            ) as? GroupCodeViewController else {
                print("ERROR: GroupCodeVC not found")
                return
            }

            // Pass existing group info
            codeVC.configure(
                withGroupName: group.name,
                code: "ABC-123"
            )
            codeVC.isFromCreateGroup = false
            
            let nav = UINavigationController(rootViewController: codeVC)
            nav.modalPresentationStyle = .pageSheet
            present(nav, animated: true)        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        if collectionView == membersCollectionView {
            let columns: CGFloat = 3
            let spacing: CGFloat = 12
            let totalSpacing = (columns - 1) * spacing + 24 // left + right insets
            let width = (collectionView.bounds.width - totalSpacing) / columns
            return CGSize(width: width, height: width + 12)
        }

        let columns: CGFloat = 3
        let spacing: CGFloat = 12
        let totalSpacing = (columns - 1) * spacing + 24
        let width = (collectionView.bounds.width - totalSpacing) / columns

        return CGSize(width: width, height: width * 0.85)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {

        return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }
}

// MARK: - Leaderboard Table
extension GroupSettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return leaderboard.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "LeaderboardCell",
            for: indexPath
        )

        let item = leaderboard[indexPath.row]
        cell.textLabel?.text = "\(indexPath.row + 1). \(item.name)"
        cell.detailTextLabel?.text = "\(item.score)"
        cell.selectionStyle = .none
        return cell
    }
}

