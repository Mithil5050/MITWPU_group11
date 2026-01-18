//
//  SummaryViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 18/01/26.
//


import UIKit

class SummaryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // Connect this to the Table View in Storyboard
    @IBOutlet weak var tableView: UITableView!
    
    // Data passed from Results Screen
    var summaryList: [QuizSummaryItem] = []
    
    // Track expanded rows
    var expandedRows: Set<Int> = []

    override func viewDidLoad() {
            super.viewDidLoad()
            title = "Summary"

            // ✅ Register the XIB file
            let nib = UINib(nibName: "QuestionSummaryCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "SummaryCell")

            tableView.delegate = self
            tableView.dataSource = self

            // Crucial for expandable cells
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 200 // Increased estimate
            tableView.tableFooterView = UIView()
            tableView.separatorStyle = .none
            // Set the background color to match the card's outer background
            tableView.backgroundColor = .systemGroupedBackground
        }

    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return summaryList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            // ✅ FIX: Cast to 'QuestionSummaryCell', NOT 'SummaryTableViewCell'
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCell", for: indexPath) as? QuestionSummaryCell else {
                return UITableViewCell()
            }
            
            let item = summaryList[indexPath.row]
            let isExpanded = expandedRows.contains(indexPath.row)
            
            // This 'configure' method belongs to QuestionSummaryCell
            cell.configure(with: item, index: indexPath.row, isExpanded: isExpanded)
            
            return cell
        }
    
    // MARK: - Expand/Collapse Logic
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            
            // 1. Toggle the state in your data model
            if expandedRows.contains(indexPath.row) {
                expandedRows.remove(indexPath.row)
            } else {
                expandedRows.insert(indexPath.row)
            }
            
            // 2. ✅ FIX: Immediately update the cell's UI
            // We get the specific cell being tapped and tell it to re-configure itself
            if let cell = tableView.cellForRow(at: indexPath) as? QuestionSummaryCell {
                let item = summaryList[indexPath.row]
                let isExpanded = expandedRows.contains(indexPath.row)
                
                // This toggles the hidden status of the dropdown view
                cell.configure(with: item, index: indexPath.row, isExpanded: isExpanded)
            }
            
            // 3. Tell the TableView to re-calculate heights (Animations)
            tableView.performBatchUpdates(nil, completion: nil)
            
            // Optional: Scroll slightly to ensure the expanded area is visible
            tableView.scrollToRow(at: indexPath, at: .none, animated: true)
        }
}
