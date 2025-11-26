//
//  StudyFolderViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import UIKit

class StudyFolderViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {

    let studyTableView = UITableView(frame: .zero, style: .plain)
       
       // Simple placeholder data so the table shows something.
       private let studyMaterials: [String] = [
           "Calculus",
           "Big Data",
           "MMA",
           "Swift Fundamentals",
           "Computer Networks"
       ]
       
       override func viewDidLoad() {
           super.viewDidLoad()
           
           // Set background color for debugging/clarity
           view.backgroundColor = .systemBackground
           
           // 1. Add the Table View as a subview
           view.addSubview(studyTableView)
           
           // 2. IMPORTANT: Must be false for Auto Layout constraints to work
           studyTableView.translatesAutoresizingMaskIntoConstraints = false
           
           // 3. Set the manager protocols
           studyTableView.dataSource = self
           studyTableView.delegate = self
           
           // 4. Register the cell identifier (Since we aren't using a prototype cell)
           studyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "StudyCell")
           
           // 5. Configure content inset adjustment behavior (replacement for deprecated automaticallyAdjustsScrollViewInsets)
           if #available(iOS 11.0, *) {
               studyTableView.contentInsetAdjustmentBehavior = .never
           } else {
               // For iOS 10 and earlier, keep the old property if you still support it.
               // This line is safe on earlier OSes and avoids the deprecation warning on iOS 11+.
               automaticallyAdjustsScrollViewInsets = false
           }
           
           // 6. Set Constraints
           setupConstraints()
       }
       
       func setupConstraints() {
           
           let safeArea = view.safeAreaLayoutGuide
           
           NSLayoutConstraint.activate([
               // Pin the top to the Safe Area (below the Navigation Bar)
               studyTableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
               
               // Pin the bottom to the Safe Area (above the Tab Bar)
               studyTableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
               
               // Pin the sides edge-to-edge
               studyTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
               studyTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
           ])
       }
       
       // MARK: - UITableViewDataSource
       
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return studyMaterials.count
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           
           // Dequeue the registered cell
           let cell = tableView.dequeueReusableCell(withIdentifier: "StudyCell", for: indexPath)
           
           // Configure appearance
           cell.textLabel?.text = studyMaterials[indexPath.row]
           cell.imageView?.image = UIImage(systemName: "folder")
           cell.imageView?.tintColor = UIColor.systemBlue
           cell.accessoryType = .disclosureIndicator
           
           return cell
       }
     
       
       // MARK: - UITableViewDelegate
       
       func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
           if section == 0 {
               return "Your Materials"
           }
           return nil
       }
       
       // ... other delegate methods
   }
