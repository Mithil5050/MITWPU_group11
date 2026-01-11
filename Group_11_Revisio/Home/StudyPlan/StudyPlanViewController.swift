//
//  StudyPlanViewController.swift
//  Group_11_Revisio
//
//  Created by Your Name on 11/12/25.
//

import UIKit

class StudyPlanViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var dateCollectionView: UICollectionView!
    @IBOutlet weak var subjectCollectionView: UICollectionView!
    @IBOutlet weak var taskTableView: UITableView!
    
    // Kept to prevent crashes if still connected in Storyboard,
    // but we won't actively manipulate it for scrolling anymore.
    @IBOutlet weak var taskTableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var subjectTitleLabel: UILabel!
    
    // MARK: - Data Source
    var dateData: [Date] = []
    
    // Uses the new 'PlanSubject' model from StudyContent.swift
    var subjects: [PlanSubject] = []
    
    // State Tracking
    var selectedSubjectIndex: Int = 0
    var selectedDateIndex: Int = 0
    
    // MARK: - Date Formatters
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Mon, Tue, Wed
        return formatter
    }()
    
    // We strictly use this for day comparison now, visuals are handled by logic
    private let calendar = Calendar.current

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Load Data
        subjects = JSONDatabaseManager.shared.loadStudyPlan()
        
        // 2. Setup Data & UI
        generateDateData()
        setupCollectionViews()
        setupTableView()
        
        // 3. Initial View Update
        if !subjects.isEmpty {
            updateViewForSelectedSubject()
        }
    }
    
    // MARK: - Logic
    
    private func generateDateData() {
        // Generate dates starting from 2 days ago to simulate some history for the streaks
        let today = calendar.startOfDay(for: Date())
        
        // Adjust -2 to see past days, or 0 to start today.
        // Using -2 here to demonstrate the "Fire" streak logic immediately.
        guard let startDate = calendar.date(byAdding: .day, value: -2, to: today) else { return }
        
        for i in 0..<10 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                dateData.append(date)
            }
        }
        
        // Auto-select "Today" if present in the list
        if let todayIndex = dateData.firstIndex(where: { calendar.isDate($0, inSameDayAs: today) }) {
            selectedDateIndex = todayIndex
        }
    }
    
    private func updateViewForSelectedSubject() {
        guard selectedSubjectIndex < subjects.count else { return }
        
        let currentSubject = subjects[selectedSubjectIndex]
        
        // Update Heading
        if let label = subjectTitleLabel {
            label.text = currentSubject.name
        }
        
        // Reload Tasks
        taskTableView.reloadData()
    }

    // MARK: - Setup
    private func setupCollectionViews() {
        dateCollectionView.dataSource = self
        dateCollectionView.delegate = self
        dateCollectionView.register(UINib(nibName: "DateButtonCell", bundle: nil), forCellWithReuseIdentifier: "DateButtonCell")
        
        subjectCollectionView.dataSource = self
        subjectCollectionView.delegate = self
        subjectCollectionView.register(UINib(nibName: "SubjectCardCell", bundle: nil), forCellWithReuseIdentifier: "SubjectCardCell")
    }

    private func setupTableView() {
        taskTableView.dataSource = self
        taskTableView.delegate = self
        
        // ✅ ENABLE SCROLLING: Allows the user to swipe through the list independently
        taskTableView.isScrollEnabled = true
        
        taskTableView.register(UINib(nibName: "TaskCell", bundle: nil), forCellReuseIdentifier: "TaskCell")
        taskTableView.separatorStyle = .none
    }
}

// MARK: - UICollectionView Data Source
extension StudyPlanViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == dateCollectionView {
            return dateData.count
        } else if collectionView == subjectCollectionView {
            return subjects.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // MARK: 📅 Date Cell Configuration
        if collectionView == dateCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateButtonCell", for: indexPath) as! DateButtonCell
            
            let date = dateData[indexPath.row]
            let isSelected = (indexPath.row == selectedDateIndex)
            
            // --- Streak / Status Logic ---
            let today = calendar.startOfDay(for: Date())
            let cellDate = calendar.startOfDay(for: date)
            
            var status: DateButtonCell.DayStatus = .future
            
            if cellDate == today {
                status = .current // Show Dot •
            } else if cellDate < today {
                // Determine if it's a Streak or Missed day
                // (Simulated logic: Recent 3 days = Fire, older = Missed)
                let daysFromToday = calendar.dateComponents([.day], from: cellDate, to: today).day ?? 100
                if daysFromToday <= 3 {
                    status = .streak // Show Fire 🔥
                } else {
                    status = .missed // Show Hyphen -
                }
            } else {
                status = .future // Show Hyphen -
            }
            // -----------------------------
            
            cell.configure(day: dayFormatter.string(from: date), status: status, isSelected: isSelected)
            return cell
            
        // MARK: 📚 Subject Card Configuration
        } else if collectionView == subjectCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubjectCardCell", for: indexPath) as! SubjectCardCell
            
            let subject = subjects[indexPath.row]
            
            cell.subjectLabel.text = subject.name
            cell.nextTaskLabel.text = "Next Task = \(subject.nextTask)"
            
            // Visual Selection State
            if indexPath.row == selectedSubjectIndex {
                cell.layer.borderWidth = 2.0
                cell.layer.borderColor = UIColor.systemBlue.cgColor
                cell.layer.cornerRadius = 16 // Matches the XIB corner radius
            } else {
                cell.layer.borderWidth = 0
            }
            
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == dateCollectionView {
            selectedDateIndex = indexPath.row
            collectionView.reloadData()
            
        } else if collectionView == subjectCollectionView {
            // Switch Subject Logic
            selectedSubjectIndex = indexPath.row
            updateViewForSelectedSubject()
            
            // Update UI for selection border
            collectionView.reloadData()
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == dateCollectionView {
            return CGSize(width: 52, height: 80) // Matches XIB size
        } else {
            return CGSize(width: collectionView.bounds.width * 0.85, height: 136)
        }
    }
}

// MARK: - UITableViewDataSource, Delegate
extension StudyPlanViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if subjects.isEmpty { return 0 }
        return subjects[selectedSubjectIndex].days.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if subjects.isEmpty { return 0 }
        return subjects[selectedSubjectIndex].days[section].tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        
        let task = subjects[selectedSubjectIndex].days[indexPath.section].tasks[indexPath.row]
        
        cell.titleLabel.text = task.title
        cell.subtitleLabel.text = task.type
        cell.setIsComplete(task.isComplete)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let task = subjects[selectedSubjectIndex].days[indexPath.section].tasks[indexPath.row]
        
        // Navigation Handler
        performTaskAction(task: task)
    }
    
    func performTaskAction(task: PlanTask) {
        if task.type.contains("Quiz") {
            print("🚀 Opening Quiz for: \(task.title)")
            // let quizVC = storyboard?.instantiateViewController(withIdentifier: "QuizViewController") as! QuizViewController
            // navigationController?.pushViewController(quizVC, animated: true)
            
        } else if task.type.contains("Notes") || task.type.contains("Revision") {
            print("📝 Opening Notes for: \(task.title)")
            // let notesVC = storyboard?.instantiateViewController(withIdentifier: "NotesViewController") as! NotesViewController
            // navigationController?.pushViewController(notesVC, animated: true)
        }
    }
    
    // MARK: - Table View Headers (Day 1, Day 2)
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .secondaryLabel
        
        if subjects.indices.contains(selectedSubjectIndex) {
            let dayNum = subjects[selectedSubjectIndex].days[section].dayNumber
            label.text = "Day \(dayNum)"
        }
        
        headerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
}
