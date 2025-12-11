//
//  StudyPlanViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 10/12/25.
//

import UIKit

class StudyPlanViewController: UIViewController {

    // MARK: - IBOutlets

    // 1. The main vertical scroll view (created in Storyboard/XIB)
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    // 2. Collection View for Date Buttons (Calendar)
    @IBOutlet weak var dateCollectionView: UICollectionView!
    
    // 3. Collection View for Subject Cards
    @IBOutlet weak var subjectCollectionView: UICollectionView!
    
    // 4. Table View for the vertical list of Tasks (needs constraints disabled for scrolling)
    @IBOutlet weak var taskTableView: UITableView!
    
    // 5. CRUCIAL: Height constraint for the taskTableView to prevent vertical scrolling conflict
    // You MUST create this constraint in Storyboard and connect it here.
    @IBOutlet weak var taskTableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Data Source Example
    
    let days: [String] = ["Fri", "Sat", "Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat", "Sun"]
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // setupUI() // Uncomment this when you want to set navigation bar items
        setupCollectionViews()
        setupTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // CRUCIAL FIX: Force layout pass and then update the height constraint.
        // This ensures the mainScrollView can determine the content size accurately.
        taskTableView.layoutIfNeeded()
        taskTableViewHeightConstraint.constant = taskTableView.contentSize.height
    }

    // MARK: - Setup
//
//     private func setupUI() {
//         // Set the Navigation Bar style (e.g., small title)
//         title = "Study Plan"
//
//         // Add left and right bar button items
//         navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
//         navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addTapped))
//     }
    
    private func setupCollectionViews() {
        // Date Collection View
        dateCollectionView.dataSource = self
        dateCollectionView.delegate = self
        // Register the XIB for the date button cell
        let dateCellNib = UINib(nibName: "DateButtonCell", bundle: nil)
        dateCollectionView.register(dateCellNib, forCellWithReuseIdentifier: "DateButtonCell")
        
        // Subject Collection View
        subjectCollectionView.dataSource = self
        subjectCollectionView.delegate = self
        let subjectCellNib = UINib(nibName: "SubjectCardCell", bundle: nil)
        subjectCollectionView.register(subjectCellNib, forCellWithReuseIdentifier: "SubjectCardCell")
    }

    private func setupTableView() {
        taskTableView.dataSource = self
        taskTableView.delegate = self
        // **CRITICAL FIX: Table View Scrolling MUST be disabled when embedded.**
        taskTableView.isScrollEnabled = true
        // Register the XIB for the task list cell
        let taskCellNib = UINib(nibName: "TaskCell", bundle: nil)
        taskTableView.register(taskCellNib, forCellReuseIdentifier: "TaskCell")
        taskTableView.separatorStyle = .none // The design suggests no default separators
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
extension StudyPlanViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == dateCollectionView {
            return days.count
        } else if collectionView == subjectCollectionView {
            // Assuming 5 subjects for the initial view
            return 5
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == dateCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateButtonCell", for: indexPath) as? DateButtonCell else {
                return UICollectionViewCell()
            }
            
            // --- Dynamic Date Configuration ---
            let dayAbbreviation = days[indexPath.row]
            // Calculate an arbitrary date number based on index (For visual display only)
            let dateNumber = "\(indexPath.row + 10)"
            
            // Example: Set the 5th day (Tue) as selected to match the design.
            let isSelected = (indexPath.row == 4)
            
            cell.configure(day: dayAbbreviation, dateNumber: dateNumber, isSelected: isSelected)
            // --- End Configuration ---
            
            return cell
            
        } else if collectionView == subjectCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubjectCardCell", for: indexPath) as? SubjectCardCell else {
                return UICollectionViewCell()
            }
            // Example: Configure Subject Cards Dynamically
            if indexPath.row == 0 {
                cell.subjectLabel.text = "Calculus"
            } else if indexPath.row == 1 {
                cell.subjectLabel.text = "Big Data"
            } else if indexPath.row == 2 {
                cell.subjectLabel.text = "MMA"
            } else if indexPath.row == 3 {
                cell.subjectLabel.text = "OS"
            } else if indexPath.row == 4 {
                cell.subjectLabel.text = "Chemistry"
            } else if indexPath.row == 5 {
                cell.subjectLabel.text = "Peace"
            } else {
                 cell.subjectLabel.text = "Subject \(indexPath.row)"
            }
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    // UICollectionViewDelegateFlowLayout for size customization
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == dateCollectionView {
            // Fixed size for the round date buttons (e.g., 60x60)
            return CGSize(width: 60, height: 60)
        } else if collectionView == subjectCollectionView {
            // Cards fill most of the screen, leaving a peek of the next one
            let collectionViewWidth = collectionView.bounds.width
            let desiredWidth = collectionViewWidth * 0.85 // e.g., 85% of screen width
            return CGSize(width: desiredWidth, height: collectionView.bounds.height)
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == dateCollectionView {
            return 8.0 // Small gap between date buttons
        } else if collectionView == subjectCollectionView {
            return 12.0 // Gap between subject cards
        }
        return 0.0
    }
}

// MARK: - UITableViewDataSource
extension StudyPlanViewController: UITableViewDataSource {
    
    // MODIFIED: Returns 4 sections for Day 1 through Day 4
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4 // Day 1, Day 2, Day 3, and Day 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Consistent number of tasks per day
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as? TaskCell else {
            return UITableViewCell()
        }
        
        // Configuration for Task Cells
        switch indexPath.section {
        case 0: // Day 1
            cell.titleLabel.text = indexPath.row == 0 ? "Practice Problems - Limits" : "Summarize Integral Concepts"
            cell.subtitleLabel.text = indexPath.row == 0 ? "Quiz" : "Short Notes"
        case 1: // Day 2
            cell.titleLabel.text = indexPath.row == 0 ? "Practice Problems - Data Lakes" : "Summarize ETL Concepts"
            cell.subtitleLabel.text = indexPath.row == 0 ? "Quiz" : "Short Notes"
        case 2: // Day 3
            cell.titleLabel.text = indexPath.row == 0 ? "Review Calculus Theorems" : "Practice Big Data Queries"
            cell.subtitleLabel.text = indexPath.row == 0 ? "Revision" : "Quiz"
        case 3: // Day 4
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
extension StudyPlanViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .headline) // iOS style headline font
        
        // Set header title: "Day 1", "Day 2", etc.
        label.text = "Day \(section + 1)"
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            // Align header text with cell content padding
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            // Pin to bottom for vertical alignment
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Reduced height for the Day X header to save space
        return 24.0
    }
}
