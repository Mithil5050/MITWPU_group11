//
//  ReviewDetailViewController.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 14/12/25.
//

import UIKit

class ReviewDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var reviewTableView: UITableView!
    
    var summaryList: [QuizSummaryItem] = []
    var expandedRows: Set<Int> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Review Summary"

        let nib = UINib(nibName: "QuestionSummaryCell", bundle: nil)
        reviewTableView.register(nib, forCellReuseIdentifier: "SummaryCell")

        reviewTableView.delegate = self
        reviewTableView.dataSource = self

        reviewTableView.rowHeight = UITableView.automaticDimension
        reviewTableView.estimatedRowHeight = 250
        reviewTableView.tableFooterView = UIView()
        reviewTableView.separatorStyle = .none
        reviewTableView.backgroundColor = .systemGroupedBackground
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return summaryList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCell", for: indexPath) as? QuestionSummaryCell else {
            return UITableViewCell()
        }
        
        let item = summaryList[indexPath.row]
        let isExpanded = expandedRows.contains(indexPath.row)
        
        cell.configure(with: item, index: indexPath.row, isExpanded: isExpanded)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if expandedRows.contains(indexPath.row) {
            expandedRows.remove(indexPath.row)
        } else {
            expandedRows.insert(indexPath.row)
        }
        
        if let cell = tableView.cellForRow(at: indexPath) as? QuestionSummaryCell {
            let item = summaryList[indexPath.row]
            cell.configure(with: item, index: indexPath.row, isExpanded: expandedRows.contains(indexPath.row))
        }
        
        tableView.performBatchUpdates(nil, completion: nil)
    }
}
