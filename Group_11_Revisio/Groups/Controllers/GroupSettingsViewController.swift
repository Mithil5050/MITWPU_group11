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
    @IBOutlet weak var linksView: UIView!
    
    
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var membersCountLabel: UILabel!
    
    //Collecton View outlets
    @IBOutlet weak var membersCollectionView: UICollectionView!
    
    @IBOutlet weak var docsCollectionView: UICollectionView!

    @IBOutlet weak var mediaView: UIView!
    
    @IBOutlet weak var linksTableView: UITableView!
    
    
    // Data
    var group: Group!
    
    weak var delegate: LeaveGroupDelegate?
    weak var updateDelegate: GroupUpdateDelegate?
    
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
    
    private let links: [(title: String, url: String)] = [
        ("Apple Developer", "https://developer.apple.com"),
        ("Swift Documentation", "https://docs.swift.org"),
        ("UIKit Guide", "https://developer.apple.com/documentation/uikit"),
        ("Human Interface Guidelines", "https://developer.apple.com/design/human-interface-guidelines")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.selectedSegmentIndex = 0
        showSegment(index: 0)
        
        // Header content
        groupNameLabel.text = group?.name ?? "Group"

        membersCountLabel.text = "\(members.count) members"
        
        groupImageView.image = UIImage(systemName: "person.3.fill")
        groupImageView.tintColor = .white
        
        //Edit Button
        let editButton = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
        navigationItem.rightBarButtonItem = editButton
        
        docsCollectionView.dataSource = self
        docsCollectionView.delegate = self
        membersCollectionView.dataSource = self
        membersCollectionView.delegate = self
        linksTableView.dataSource = self
        linksTableView.delegate = self
    }
    
    //MARK: - Edit button
    @objc private func editButtonTapped() {

        let renameAction = UIAlertAction(
            title: "Change Group Name",
            style: .default
        ) { [weak self] _ in
            self?.presentRenameGroup()
        }

        let avatarAction = UIAlertAction(
            title: "Change Group Avatar",
            style: .default
        ) { _ in
            // avatar later
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        let sheet = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )

        sheet.addAction(renameAction)
        sheet.addAction(avatarAction)
        sheet.addAction(cancelAction)

        present(sheet, animated: true)
    }
    private func presentRenameGroup() {

        let alert = UIAlertController(
            title: "Edit Group Name",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField {
            $0.placeholder = "Group name"
            $0.text = self.group.name
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            guard
                let self = self,
                let newName = alert.textFields?.first?.text,
                !newName.isEmpty
            else { return }

            // Update local model
            self.group.name = newName

            // Update UI
            self.groupNameLabel.text = newName

            // Notify ChatVC
            self.updateDelegate?.didUpdateGroup(self.group)

            self.dismiss(animated: true)
        })

        present(alert, animated: true)
    }

    // MARK: - Segment control
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        showSegment(index: sender.selectedSegmentIndex)
    }

    private func showSegment(index: Int) {
        UIView.animate(withDuration: 0.2) {
            self.infoView.isHidden = index != 0
            self.docsView.isHidden = index != 1
            self.mediaView.isHidden = index != 2
            self.linksView.isHidden = index != 3

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
//MARK: - Links View
extension GroupSettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if links.isEmpty {
            let label = UILabel()
            label.text = "No links shared yet"
            label.textColor = .secondaryLabel
            label.font = UIFont.systemFont(ofSize: 15)
            label.textAlignment = .center
            label.numberOfLines = 0
            tableView.backgroundView = label
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }

        return links.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "LinkCell",
            for: indexPath
        )

        let item = links[indexPath.row]

        cell.textLabel?.text = item.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        cell.detailTextLabel?.text = item.url
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .secondaryLabel

        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        cell.imageView?.image = UIImage(systemName: "link")
        cell.imageView?.tintColor = .systemBlue
        cell.imageView?.contentMode = .scaleAspectFit
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = links[indexPath.row]
        guard let url = URL(string: item.url) else { return }

        UIApplication.shared.open(url)
    }
}

