//
//  TodaysTaskViewController.swift
//  Group_11_Revisio
//
//  Updated for JSON Data
//

import UIKit

class TodaysTaskViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var infoCollectionView: UICollectionView!
    @IBOutlet weak var taskTableView: UITableView!
    @IBOutlet weak var taskTableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Data Source
    // 🆕 Now holds the data loaded from JSON
    var todayData: [TodaySubject] = []

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Load Data
        todayData = JSONDatabaseManager.shared.loadTodaysTasks()
        
        setupCollectionViews()
        setupTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Dynamic Height Calculation
        taskTableView.layoutIfNeeded()
        taskTableViewHeightConstraint.constant = taskTableView.contentSize.height
        
        // Keep scrolling enabled for the list behavior
        taskTableView.isScrollEnabled = true // Disabled because it's inside a ScrollView
    }

    // MARK: - Setup
    private func setupCollectionViews() {
        infoCollectionView.dataSource = self
        infoCollectionView.delegate = self
        
        // Assuming you have this XIB based on your previous code
        let infoCellNib = UINib(nibName: "InfoCollectionViewCell", bundle: nil)
        infoCollectionView.register(infoCellNib, forCellWithReuseIdentifier: "InfoCollectionViewCell")
    }

    private func setupTableView() {
        taskTableView.dataSource = self
        taskTableView.delegate = self
        taskTableView.isScrollEnabled = true // Let MainScrollView handle scrolling
        
        // 🆕 Using standard "TaskCell" (matched to your XIB)
        let taskCellNib = UINib(nibName: "TaskCell", bundle: nil)
        taskTableView.register(taskCellNib, forCellReuseIdentifier: "TaskCell")
        taskTableView.separatorStyle = .none
    }
}

// MARK: - UICollectionView Data Source
extension TodaysTaskViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InfoCollectionViewCell", for: indexPath) as? InfoCollectionViewCell else {
            return UICollectionViewCell()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 90)
    }
}

// MARK: - UITableView Data Source (The New JSON Logic)
extension TodaysTaskViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return todayData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todayData[section].tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as? TaskCell else {
            return UITableViewCell()
        }
        
        // 🆕 Fetch task from JSON data array
        let task = todayData[indexPath.section].tasks[indexPath.row]
        
        cell.titleLabel.text = task.title
        cell.subtitleLabel.text = task.type
        cell.setIsComplete(task.isComplete)
        
        return cell
    }
    
    // MARK: - Section Headers
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        
        // 🆕 Use Subject Name from JSON
        label.text = todayData[section].subjectName
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
}
