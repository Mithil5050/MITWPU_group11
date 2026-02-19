//
//  AttachmentFolderViewController.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 19/02/26.
//

import UIKit

class AttachmentFolderViewController: UIViewController {
    
    private let tableView = UITableView()
    private var subjectNames: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Select Folder"
        
        setupTableView()
        fetchFolders()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func fetchFolders() {
        subjectNames = Array(DataManager.shared.savedMaterials.keys).sorted()
        tableView.reloadData()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

extension AttachmentFolderViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subjectNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = subjectNames[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedSubject = subjectNames[indexPath.row]
        
        let pickerVC = AttachmentItemPickerViewController()
        pickerVC.selectedSubject = selectedSubject
        
        navigationController?.pushViewController(pickerVC, animated: true)
    }
}
