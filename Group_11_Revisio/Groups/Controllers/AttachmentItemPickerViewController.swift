//
//  AttachmentItemPickerViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 19/02/26.
//

import UIKit

class AttachmentItemPickerViewController: UIViewController {

    var selectedSubject: String?

    private let tableView = UITableView()
    private var materials: [String] = []
    private var selectedItems: Set<String> = []
    private let segmentedControl = UISegmentedControl(items: ["Materials", "Sources"])
    private var materialItems: [StudyItem] = []
    private var sourceItems: [StudyItem] = []
    

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = selectedSubject ?? "Materials"

        setupTableView()
        fetchMaterials()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Send",
            style: .done,
            target: self,
            action: #selector(sendTapped)
        )
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        navigationItem.titleView = segmentedControl
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func fetchMaterials() {
        guard let subject = selectedSubject else { return }

        let subjectData = DataManager.shared.savedMaterials[subject] ?? [:]

        materialItems = subjectData[DataManager.materialsKey] ?? []
        sourceItems = subjectData[DataManager.sourcesKey] ?? []

        tableView.reloadData()
    }
    
    @objc private func segmentChanged() {
        tableView.reloadData()
    }

    @objc private func sendTapped() {
        print("Selected Items:", selectedItems)
        dismiss(animated: true)
    }
}

extension AttachmentItemPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segmentedControl.selectedSegmentIndex == 0
            ? materialItems.count
            : sourceItems.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let item = segmentedControl.selectedSegmentIndex == 0
            ? materialItems[indexPath.row]
            : sourceItems[indexPath.row]

        let title: String

        switch item {
        case .topic(let topic):
            title = topic.name
        case .source(let source):
            title = source.name
        }

        cell.textLabel?.text = title
        cell.accessoryType = selectedItems.contains(title) ? .checkmark : .none

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        let item = segmentedControl.selectedSegmentIndex == 0
            ? materialItems[indexPath.row]
            : sourceItems[indexPath.row]

        let title: String

        switch item {
        case .topic(let topic):
            title = topic.name
        case .source(let source):
            title = source.name
        }

        if selectedItems.contains(title) {
            selectedItems.remove(title)
        } else {
            selectedItems.insert(title)
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
