//
// TodaysTaskViewController.swift
// Group_11_Revisio
//
// Created by Mithil on 10/12/25.
//

import UIKit

// Define a section type for clarity, though not strictly required for this class
enum StudyPlanSection: Int, CaseIterable {
    case calendar = 0
    case infoCard
    case tasks
}

// NOTE: Assume these classes exist in your project with required outlets/methods
//class TaskCell2: UITableViewCell {
//    @IBOutlet weak var titleLabel: UILabel!
//    @IBOutlet weak var subtitleLabel: UILabel!
//}

class TodaysTaskViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var dateCollectionView: UICollectionView!
    @IBOutlet weak var infoCollectionView: UICollectionView!
    @IBOutlet weak var taskTableView: UITableView!
    @IBOutlet weak var taskTableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Dynamic Data Source
    
    // ⬇️ NEW: Holds the actual Date objects for the next 10 days ⬇️
    var dateData: [Date] = []
    
    // Tracks the currently selected date index (defaults to today)
    var selectedDateIndex: Int = 0
    
    // **Subject headers mapped to sections (0-3)**
    let subjectHeaders = ["Calculus", "Big Data", "Data Structures", "MMA"]

    // MARK: - Date Formatters
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Fri, Sat, Sun
        return formatter
    }()
    
    private let dateNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d" // Date number only (10, 11, 12)
        return formatter
    }()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        generateDateData() // ⬇️ NEW: Calculate the dates
        // setupUI()
        setupCollectionViews()
        setupTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // CRUCIAL FIX: Force layout pass and then update the height constraint.
        taskTableView.layoutIfNeeded()
        taskTableViewHeightConstraint.constant = taskTableView.contentSize.height
        
        // CRITICAL FIX: Ensure scrolling is disabled when embedded in a Scroll View
        taskTableView.isScrollEnabled = true
    }

    // MARK: - Setup
    
    // ⬇️ NEW: Function to generate 10 consecutive Date objects ⬇️
    private func generateDateData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Generate the current day + the next 9 days (10 total)
        for i in 0..<10 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                dateData.append(date)
            }
        }
        // Set 'Today' (index 0) as selected by default
        selectedDateIndex = 0
    }
    
    private func setupCollectionViews() {
        // Date Collection View
        dateCollectionView.dataSource = self
        dateCollectionView.delegate = self
        // Register the XIB for the date button cell
        let dateCellNib = UINib(nibName: "DateButtonCell2", bundle: nil)
        dateCollectionView.register(dateCellNib, forCellWithReuseIdentifier: "DateButtonCell")
        
        // Info Card Collection View
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
        let taskCellNib = UINib(nibName: "TaskCell2", bundle: nil)
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
            return dateData.count // ⬇️ Use the dynamic date count
        } else if collectionView == infoCollectionView {
            return 1 // Only one Info Card
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == dateCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateButtonCell", for: indexPath) as? DateButtonCell2 else {
                fatalError("Unable to dequeue DateButtonCell2 with identifier DateButtonCell. Check NIB registration or class name.")
            }
            
            // ⬇️ MODIFIED: Use Date Formatters ⬇️
            let date = dateData[indexPath.row]
            let dayAbbreviation = dayFormatter.string(from: date)
            let dateNumber = dateNumberFormatter.string(from: date)
            let isSelected = (indexPath.row == selectedDateIndex)
            
            cell.configure(day: dayAbbreviation, dateNumber: dateNumber, isSelected: isSelected)
            
            return cell
            
        } else if collectionView == infoCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InfoCollectionViewCell", for: indexPath) as? InfoCollectionViewCell else {
                fatalError("Unable to dequeue InfoCollectionViewCell. Check NIB registration or class name.")
            }
            // Configuration for the Info Card goes here if needed
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == dateCollectionView {
            // Update selection index and reload to show the change
            selectedDateIndex = indexPath.row
            collectionView.reloadData()
            
            // TODO: Reload the taskTableView based on the newly selected date
        }
    }
    
    // UICollectionViewDelegateFlowLayout for size customization
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == dateCollectionView {
            // Fixed size for the round date buttons (e.g., 52x80)
            return CGSize(width: 52, height: 80)
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
        return subjectHeaders.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            cell.titleLabel.text = indexPath.row == 0 ? "Implement Graph Traversal" : "Analyze Sorting Algorithms"
            cell.subtitleLabel.text = indexPath.row == 0 ? "Coding" : "Revision"
        case 3: // MMA
            cell.titleLabel.text = indexPath.row == 0 ? "Analyze Striking Technique Videos" : "Draft Study Group Agenda"
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
