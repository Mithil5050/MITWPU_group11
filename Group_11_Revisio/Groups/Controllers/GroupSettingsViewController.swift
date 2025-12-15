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

    // Info view outlets (inside infoView)
    @IBOutlet weak var membersCollectionView: UICollectionView!
    @IBOutlet weak var groupInfoTitleLabel: UILabel!
    @IBOutlet weak var membersCountLabel: UILabel!
    @IBOutlet weak var hideAlertsSwitch: UISwitch!
    @IBOutlet weak var leaveButton: UIButton!

    // Docs view
    @IBOutlet weak var docsCollectionView: UICollectionView!

    // Leaderboard view
    @IBOutlet weak var leaderboardTableView: UITableView!

    // Data
    var group: Group!
    weak var delegate: LeaveGroupDelegate?

    private var members: [String] = ["You","Ashika","Mithil","Ayaana"]
    private var documents: [String] = ["DBMS.pdf","Statistics.pdf","DS Qs.jpg"]
    private var leaderboard: [(name: String, score: Int)] = [("Chirag",650),("Ashika",590),("Ayaana",400)]

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.selectedSegmentIndex = 0
        showSegment(index: 0)

        groupInfoTitleLabel.text = group?.name ?? "Group"
        membersCountLabel.text = "\(members.count) members"

        // style leave button
        leaveButton.layer.cornerRadius = 12
        leaveButton.setTitleColor(.systemRed, for: .normal)
        leaveButton.backgroundColor = UIColor.systemGray6

        // register / datasource delegates
        membersCollectionView.dataSource = self
        membersCollectionView.delegate = self
        membersCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MemberCellIdentifier")

        docsCollectionView.dataSource = self
        docsCollectionView.delegate = self
        docsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "DocumentCellIdentifier")

        leaderboardTableView.dataSource = self
        leaderboardTableView.delegate = self
        leaderboardTableView.register(UITableViewCell.self, forCellReuseIdentifier: "LeaderboardCellIdentifier")
    }

    // MARK: - Segment control
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        showSegment(index: sender.selectedSegmentIndex)
    }

    private func showSegment(index: Int) {
        infoView.isHidden = index != 0
        docsView.isHidden = index != 1
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

// MARK: - Collection / Table DataSources
extension GroupSettingsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == membersCollectionView { return members.count }
        return documents.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == membersCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemberCellIdentifier", for: indexPath)
            if let label = cell.contentView.viewWithTag(101) as? UILabel {
                label.text = members[indexPath.item]
            } else {
                let lbl = UILabel(frame: cell.contentView.bounds.insetBy(dx: 4, dy: 4))
                lbl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                lbl.textAlignment = .center
                lbl.font = UIFont.systemFont(ofSize: 12)
                lbl.text = members[indexPath.item]
                lbl.tag = 101
                cell.contentView.addSubview(lbl)
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DocumentCellIdentifier", for: indexPath)
            if let label = cell.contentView.viewWithTag(201) as? UILabel {
                label.text = documents[indexPath.item]
            } else {
                let lbl = UILabel(frame: cell.contentView.bounds.insetBy(dx: 4, dy: 4))
                lbl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                lbl.font = UIFont.systemFont(ofSize: 12)
                lbl.textAlignment = .center
                lbl.numberOfLines = 2
                lbl.tag = 201
                lbl.text = documents[indexPath.item]
                cell.contentView.addSubview(lbl)
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == membersCollectionView {
            return CGSize(width: 72, height: 72)
        } else {
            let width = (collectionView.bounds.width - 24) / 2
            return CGSize(width: width, height: width * 0.7)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == membersCollectionView {
            print("Tapped member:", members[indexPath.item])
        } else {
            print("Open doc:", documents[indexPath.item])
        }
    }
}

extension GroupSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { leaderboard.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardCellIdentifier", for: indexPath)
        let item = leaderboard[indexPath.row]
        cell.textLabel?.text = "\(indexPath.row + 1). \(item.name)"
        cell.detailTextLabel?.text = "\(item.score)"
        cell.selectionStyle = .none
        return cell
    }
}
