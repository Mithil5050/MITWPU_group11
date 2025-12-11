//
//  GroupSettingsViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 11/12/25.
//

import UIKit

class GroupSettingsViewController: UIViewController {

    // MARK: - IBOutlets (connect in storyboard)
        @IBOutlet weak var segmentedControl: UISegmentedControl!
        @IBOutlet weak var infoView: UIView!
        @IBOutlet weak var docsView: UIView!
        @IBOutlet weak var leaderboardView: UIView!

        // Info view outlets
        @IBOutlet weak var groupTitleLabel: UILabel!
        @IBOutlet weak var hideAlertsSwitch: UISwitch!

        // Docs view
        @IBOutlet weak var docsCollectionView: UICollectionView!

        // Leaderboard view
        @IBOutlet weak var leaderboardTableView: UITableView!

        // Leave button
        @IBOutlet weak var leaveButton: UIButton!

        // Data
        var group: Group!
        weak var delegate: LeaveGroupDelegate?

        // sample content (replace with real data later)
        private var documents: [String] = ["DBMS.pdf","Statistics.pdf","DS Questions.jpeg","Partial Derivatives.pdf","Formulae.jpeg","Swift Language.pdf"]
        private var leaderboard: [(name: String, score: Int)] = [
            ("Chirag", 650),
            ("Ashika", 590),
            ("Ayaana", 400),
            ("Mithil", 250)
        ]

        override func viewDidLoad() {
            super.viewDidLoad()

            // wire up UI defaults
            segmentedControl.selectedSegmentIndex = 0
            showSegment(index: 0)

            // update group name label
            groupTitleLabel.text = group?.name ?? "Group"

            // style leave button
            leaveButton.layer.cornerRadius = 14
            leaveButton.backgroundColor = UIColor.systemGray6
            leaveButton.setTitleColor(.systemRed, for: .normal)

            // collection & table delegates
            docsCollectionView.dataSource = self
            docsCollectionView.delegate = self

            leaderboardTableView.dataSource = self
            leaderboardTableView.delegate = self

            // register fallback cells if you haven't created custom cells yet
            docsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "DocumentCell")
            leaderboardTableView.register(UITableViewCell.self, forCellReuseIdentifier: "LeaderboardCell")
        }

        // MARK: - Segmented control
        @IBAction func segmentChanged(_ sender: UISegmentedControl) {
            showSegment(index: sender.selectedSegmentIndex)
        }

        private func showSegment(index: Int) {
            infoView.isHidden = index != 0
            docsView.isHidden = index != 1
            leaderboardView.isHidden = index != 2
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
}

    // MARK: - UICollectionView DataSource / DelegateFlowLayout
    extension GroupSettingsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return documents.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            // fallback simple cell (you can create a custom DocumentCell.xib later)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DocumentCell", for: indexPath)
            if let label = cell.contentView.viewWithTag(101) as? UILabel {
                label.text = documents[indexPath.row]
            } else {
                // minimal default: add a label if cell is plain
                let lbl = UILabel(frame: cell.contentView.bounds.insetBy(dx: 4, dy: 4))
                lbl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                lbl.font = UIFont.systemFont(ofSize: 12)
                lbl.textAlignment = .center
                lbl.numberOfLines = 2
                lbl.text = documents[indexPath.row]
                lbl.tag = 101
                cell.contentView.addSubview(lbl)
            }
            return cell
        }

        // size: 3 columns
        func collectionView(_ collectionView: UICollectionView, layout
            collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let totalSpacing: CGFloat = 32 // 16 left + 16 right + gaps
            let available = collectionView.bounds.width - totalSpacing
            let width = (available - 24) / 3 // 3 columns with spacing
            return CGSize(width: width, height: width + 24)
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            // placeholder: open document
            print("Tapped doc:", documents[indexPath.row])
        }
}


    // MARK: - UITableView DataSource / Delegate (leaderboard)
extension GroupSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return leaderboard.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardCell", for: indexPath)
        let item = leaderboard[indexPath.row]
        cell.textLabel?.text = "\(indexPath.row + 1). \(item.name)"
        cell.detailTextLabel?.text = "\(item.score)"
        cell.selectionStyle = .none
        return cell
    }
}
