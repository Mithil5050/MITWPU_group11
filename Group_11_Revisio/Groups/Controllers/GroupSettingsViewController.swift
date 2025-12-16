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
//    @IBOutlet weak var leaderboardView: UIView!
//
//    // Info view outlets (inside infoView)
//    @IBOutlet weak var membersCollectionView: UICollectionView!
//    @IBOutlet weak var groupInfoTitleLabel: UILabel!
//    @IBOutlet weak var membersCountLabel: UILabel!
//    @IBOutlet weak var hideAlertsSwitch: UISwitch!
//    @IBOutlet weak var leaveButton: UIButton!
//
    // Docs view
    @IBOutlet weak var docsCollectionView: UICollectionView!
//
//    // Leaderboard view
//    @IBOutlet weak var leaderboardTableView: UITableView!

    // Data
    var group: Group!
    weak var delegate: LeaveGroupDelegate?

    //private let members: [(name: String, avatar: String)] = [("You", "pfp1"), ("Ashika", "pfp2"), ("Mithil", "pfp3"), ("Ayaana", "pfp4")]
    
    private var documents: [String] = ["DBMS.pdf","Statistics.pdf","DS QB.jpg","DETT.pdf","Operating systems.jpg"]
    private var leaderboard: [(name: String, score: Int)] = [("Chirag",650),("Ashika",590),("Ayaana",400)]

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.selectedSegmentIndex = 0
        showSegment(index: 0)

        //groupInfoTitleLabel.text = group?.name ?? "Group"
        //membersCountLabel.text = "\(members.count) members"

        // style leave button
        //leaveButton.layer.cornerRadius = 12
        //leaveButton.setTitleColor(.systemRed, for: .normal)
        //leaveButton.backgroundColor = UIColor.systemGray6

        // register / datasource delegates
//        membersCollectionView.dataSource = self
//        membersCollectionView.delegate = self
//        membersCollectionView.register(MemberCell.self, forCellWithReuseIdentifier: "MemberCellIdentifier")

        docsCollectionView.dataSource = self
        docsCollectionView.delegate = self

        //leaderboardTableView.dataSource = self
        //leaderboardTableView.delegate = self
        //leaderboardTableView.register(UITableViewCell.self, forCellReuseIdentifier: "LeaderboardCellIdentifier")
    }

    // MARK: - Segment control
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        showSegment(index: sender.selectedSegmentIndex)
    }

    private func showSegment(index: Int) {
        infoView?.isHidden = true
        docsView?.isHidden = true

        if index == 0 {
            infoView?.isHidden = false
        } else if index == 1 {
            docsView?.isHidden = false
        }
    }

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
        return documents.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "DocumentCellIdentifier",
            for: indexPath
        ) as! DocumentCell

        cell.configure(title: documents[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let columns: CGFloat = 3
        let spacing: CGFloat = 12

        let totalSpacing = (columns - 1) * spacing + 24 // 12 left + 12 right
        let width = (collectionView.bounds.width - totalSpacing) / columns

        return CGSize(width: width, height: width * 0.85)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
}

//extension GroupSettingsViewController: UITableViewDataSource, UITableViewDelegate {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { leaderboard.count }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardCellIdentifier", for: indexPath)
//        let item = leaderboard[indexPath.row]
//        cell.textLabel?.text = "\(indexPath.row + 1). \(item.name)"
//        cell.detailTextLabel?.text = "\(item.score)"
//        cell.selectionStyle = .none
//        return cell
//    }
//}

