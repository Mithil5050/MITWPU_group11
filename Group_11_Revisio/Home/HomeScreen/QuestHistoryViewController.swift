//
//  QuestHistoryViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 29/01/26.
//


import UIKit

class QuestHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var history: [SideQuest] = []
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .systemBackground
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Completed Quests"
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        
        if history.isEmpty {
            showEmptyState()
        }
    }
    
    private func showEmptyState() {
        let label = UILabel()
        label.text = "No quests completed yet!"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.center = view.center
        view.addSubview(label)
        label.frame = CGRect(x: 0, y: 0, width: 300, height: 50)
        label.center = view.center
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let quest = history[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = quest.title
        content.image = UIImage(systemName: "checkmark.circle.fill")
        content.imageProperties.tintColor = .systemIndigo
        
        cell.contentConfiguration = content
        return cell
    }
}
