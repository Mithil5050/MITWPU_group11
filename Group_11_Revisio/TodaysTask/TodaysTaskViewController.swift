//
//  TodaysTaskViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 10/12/25.
//

import UIKit

// Define a section type for clarity, though not strictly required for this class
enum StudyPlanSection: Int, CaseIterable {
    case calendar = 0
    case infoCard
    case tasks
}

class TodaysTaskViewController: UIViewController {

    // MARK: - IBOutlets

    // 1. The main vertical scroll view (created in Storyboard/XIB)
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    // 2. Collection View for Date Buttons (Calendar)
    @IBOutlet weak var dateCollectionView: UICollectionView!
    
    // 3. Info Card View (Replaces subjectCollectionView - Assuming a UICollectionView for the card)
    @IBOutlet weak var infoCollectionView: UICollectionView!
    
    // 4. Table View for the vertical list of Tasks
    @IBOutlet weak var taskTableView: UITableView!
    
    // 5. CRUCIAL: Height constraint for the taskTableView
    @IBOutlet weak var taskTableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Data Source Example
    
    let days: [String] = ["Fri", "Sat", "Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat", "Sun"]
    
    // **NEW: Subject headers mapped to sections (0-3)**
    let subjectHeaders = ["Calculus", "Big Data", "Data Structures", "MMA"]

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // setupUI()
        setupCollectionViews()
        setupTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // CRUCIAL FIX: Force layout pass and then update the height constraint.
        taskTableView.layoutIfNeeded()
        taskTableViewHeightConstraint.constant = taskTableView.contentSize.height
    }

    // MARK: - Setup
    
    private func setupCollectionViews() {
        // Date Collection View
        dateCollectionView.dataSource = self
        dateCollectionView.delegate = self
        // Register the XIB for the date button cell
        let dateCellNib = UINib(nibName: "DateButtonCell2", bundle: nil)
        dateCollectionView.register(dateCellNib, forCellWithReuseIdentifier: "DateButtonCell")
        
        // Info Card Collection View (NEW)
        infoCollectionView.dataSource = self
        infoCollectionView.delegate = self
        // Register the XIB for the Info Card cell
        let infoCellNib = UINib(nibName: "InfoCollectionViewCell", bundle: nil)
        infoCollectionView.register(infoCellNib, forCellWithReuseIdentifier: "InfoCollectionViewCell")
    }

    private func setupTableView() {
        taskTableView.dataSource = self
        taskTableView.delegate = self
        // CRITICAL FIX: Table View Scrolling MUST be disabled when embedded.
        taskTableView.isScrollEnabled = true
        
        // Register the XIB for the task list cell
        let taskCellNib = UINib(nibName: "TaskCell2", bundle: nil) // Using TaskCell2 from the uploaded file
        taskTableView.register(taskCellNib, forCellReuseIdentifier: "TaskCell")
        taskTableView.separatorStyle = .none
    }
    
    // MARK: - Actions
    
    @objc func backTapped() {
        // Handle back action
    }
    
    @objc func addTapped() {
        // Handle add/plus action
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension TodaysTaskViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == dateCollectionView {
            return days.count // Multiple days
        } else if collectionView == infoCollectionView {
            return 1 // Only one Info Card
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == dateCollectionView {
            // REUSE ID and CAST MUST MATCH
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateButtonCell", for: indexPath) as? DateButtonCell2 else {
                fatalError("Unable to dequeue DateButtonCell2 with identifier DateButtonCell. Check NIB registration or class name.")
            }
            
            // --- Dynamic Date Configuration ---
            let dayAbbreviation = days[indexPath.row]
            let dateNumber = "\(indexPath.row + 10)"
            let isSelected = (indexPath.row == 4)
            
            cell.configure(day: dayAbbreviation, dateNumber: dateNumber, isSelected: isSelected)
            // --- End Configuration ---
            
            return cell
            
        } else if collectionView == infoCollectionView {
            // New Info Card Cell
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InfoCollectionViewCell", for: indexPath) as? InfoCollectionViewCell else {
                fatalError("Unable to dequeue InfoCollectionViewCell. Check NIB registration or class name.")
            }
            // Configuration for the Info Card goes here if needed
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    // UICollectionViewDelegateFlowLayout for size customization
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == dateCollectionView {
            // Fixed size for the round date buttons (e.g., 60x60)
            return CGSize(width: 52, height: 80) // Using size from DateButtonCell2.xib
        } else if collectionView == infoCollectionView {
            // Info Card must span the full width of the collection view
            let collectionViewWidth = collectionView.bounds.width
            // Height is estimated from InfoCollectionViewCell.xib (90pt)
            return CGSize(width: collectionViewWidth, height: 90)
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == dateCollectionView {
            return 8.0 // Small gap between date buttons
        } else if collectionView == infoCollectionView {
            return 0.0 // No spacing needed for a single card
        }
        return 0.0
    }
}

// MARK: - UITableViewDataSource
extension TodaysTaskViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // We use the count of the subject headers array (4)
        return subjectHeaders.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Using the "TaskCell" identifier for the TaskCell2 implementation
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as? TaskCell2 else {
            return UITableViewCell()
        }
        
        // Configuration for Task Cells based on Subject Section
        switch indexPath.section {
        case 0: // Calculus
            cell.titleLabel.text = indexPath.row == 0 ? "Practice Problems - Limits" : "Summarize Integral Concepts"
            cell.subtitleLabel.text = indexPath.row == 0 ? "Quiz" : "Short Notes"
        case 1: // Big Data
            cell.titleLabel.text = indexPath.row == 0 ? "Practice Problems - Data Lakes" : "Summarize ETL Concepts"
            cell.subtitleLabel.text = indexPath.row == 0 ? "Quiz" : "Short Notes"
        case 2: // Data Structures
            cell.titleLabel.text = indexPath.row == 0 ? "Review Calculus Theorems" : "Practice Big Data Queries"
            cell.subtitleLabel.text = indexPath.row == 0 ? "Revision" : "Quiz"
        case 3: // MMA
            cell.titleLabel.text = indexPath.row == 0 ? "Analyze MMA Technique Videos" : "Draft Study Group Agenda"
            cell.subtitleLabel.text = indexPath.row == 0 ? "Notes" : "Planning"
        default:
            cell.titleLabel.text = "Error"
            cell.subtitleLabel.text = "Task Missing"
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TodaysTaskViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        
        // **MODIFIED: Use the subject name from the array**
        if section < subjectHeaders.count {
            label.text = subjectHeaders[section]
        }
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 24.0
    }
}
