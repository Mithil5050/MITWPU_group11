//
//  ProgressViewContoller.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 27/11/25.
//

import UIKit

class ProgressViewContoller: UIViewController, LogStudyTimeDelegate {
    
    @IBOutlet weak var hoursGraphView: UIView!
    var chart = BarGraphView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Set up chart
        chart.translatesAutoresizingMaskIntoConstraints = false
        chart.backgroundColor = .clear
        chart.values = [4, 7, 6, 10, 5, 9]   // initial values

        hoursGraphView.addSubview(chart)

        NSLayoutConstraint.activate([
            chart.leadingAnchor.constraint(equalTo: hoursGraphView.leadingAnchor, constant: 12),
            chart.trailingAnchor.constraint(equalTo: hoursGraphView.trailingAnchor, constant: -12),
            chart.topAnchor.constraint(equalTo: hoursGraphView.topAnchor, constant: 12),
            chart.bottomAnchor.constraint(equalTo: hoursGraphView.bottomAnchor, constant: -12)
        ])
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            chart.values = [2, 4, 3, 6, 7, 5, 6]
        } else {
            chart.values = [4, 7, 6, 10, 5, 9, 8]
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 🚨 IMPORTANT: Replace "LogStudyTimeSegue" with the actual Identifier you set on your Storyboard Segue.
        if segue.identifier == "LogStudyTime" {
            // Check if the destination is a Navigation Controller (since you need the top bar UI)
            if let navigationController = segue.destination as? UINavigationController,
               let logStudyVC = navigationController.viewControllers.first as? LogProgressViewController {
                // ⭐️ Set the delegate to THIS view controller (ProgressViewContoller)
                logStudyVC.delegate = self
                // ⭐️ FIX for Blur Effect: Ensure the presentation style keeps the background visible
                navigationController.modalPresentationStyle = .overCurrentContext
            }
        }
    }

    // MARK: - Delegate Method (Receives Data from Modal)
    func didLogStudyTime(hours: Double, date: Date, subject: String?) {
        print("✅ Data received: \(hours) hours logged on \(date) for \(subject ?? "Unknown")")
        // 1. Save this data to your database (Core Data, Realm, etc.)
        // 2. Refresh your charts and achievement cards to reflect the new entry
        // Example: If you have a chart outlet named 'barChart'
        // self.barChart.reloadData()
    }
}
