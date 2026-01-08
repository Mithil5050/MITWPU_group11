//
// StudyPlanViewController.swift
// Group_11_Revisio
//
// Created by Mithil on 10/12/25.
//

import UIKit

class StudyPlanViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var dateCollectionView: UICollectionView!
    @IBOutlet weak var subjectCollectionView: UICollectionView!
    @IBOutlet weak var taskTableView: UITableView!
    @IBOutlet weak var taskTableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Data Source
    
    // ⬇️ MODIFIED: Holds the actual Date objects for the next 10 days ⬇️
    var dateData: [Date] = []
    
    // Tracks the currently selected date index (e.g., today is index 0)
    var selectedDateIndex: Int = 0
    
    // MARK: - Date Formatters (Heavyweight objects, created once)
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
        
        // CRUCIAL FIX: Ensures the mainScrollView can determine the content size accurately.
        taskTableView.layoutIfNeeded()
        taskTableViewHeightConstraint.constant = taskTableView.contentSize.height
        
        // Disable table view scrolling when embedded in a scroll view
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
        // CRITICAL FIX: Ensure scrolling is disabled when embedded in a Scroll View
        taskTableView.isScrollEnabled = true
        // Register the XIB for the task list cell
        let taskCellNib = UINib(nibName: "TaskCell", bundle: nil)
        taskTableView.register(taskCellNib, forCellReuseIdentifier: "TaskCell")
        taskTableView.separatorStyle = .none
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension StudyPlanViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == dateCollectionView {
            return dateData.count // ⬇️ Use the dynamic date count
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
            
            let date = dateData[indexPath.row]
            
            // ⬇️ MODIFIED: Use Date Formatters ⬇️
            let dayAbbreviation = dayFormatter.string(from: date)
            let dateNumber = dateNumberFormatter.string(from: date)
            
            // Check against the dynamically tracked selection index
            let isSelected = (indexPath.row == selectedDateIndex)
            
            cell.configure(day: dayAbbreviation, dateNumber: dateNumber, isSelected: isSelected)
            
            return cell
            
        } else if collectionView == subjectCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubjectCardCell", for: indexPath) as? SubjectCardCell else {
                return UICollectionViewCell()
            }
            // Example: Configure Subject Cards Dynamically
            switch indexPath.row {
            case 0: cell.subjectLabel.text = "Calculus"
            case 1: cell.subjectLabel.text = "Big Data"
            case 2: cell.subjectLabel.text = "MMA"
            case 3: cell.subjectLabel.text = "OS"
            case 4: cell.subjectLabel.text = "Chemistry"
            default: cell.subjectLabel.text = "Subject \(indexPath.row)"
            }
            
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
            // Fixed size for the round date buttons (e.g., 60x60)
            return CGSize(width: 60, height: 60)
        } else if collectionView == subjectCollectionView {
            // Cards fill most of the screen, leaving a peek of the next one
            let collectionViewWidth = collectionView.bounds.width
            let desiredWidth = collectionViewWidth * 0.85
            return CGSize(width: desiredWidth, height: collectionView.bounds.height)
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == dateCollectionView {
            return 8.0
        } else if collectionView == subjectCollectionView {
            return 12.0
        }
        return 0.0
    }
}

// MARK: - UITableViewDataSource
extension StudyPlanViewController: UITableViewDataSource {
    
    // MODIFIED: Returns 4 sections for Day 1 through Day 4 (Example Tasks)
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2 // Consistent number of tasks per day
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as? TaskCell else {
            return UITableViewCell()
        }
        
        // Configuration for Task Cells (Example data)
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
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        
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
        return 24.0
    }
}
