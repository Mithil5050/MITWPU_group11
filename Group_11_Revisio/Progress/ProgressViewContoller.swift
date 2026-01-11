//
//  ProgressViewContoller.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 27/11/25.
//

import UIKit
import SwiftUI
import Charts

class ProgressViewContoller: UIViewController , LogStudyTimeDelegate {
    
    
    @IBOutlet weak var chartContainerView: UIView!
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var streaksCard: UIView!
    
    @IBOutlet weak var awardsCard: UIView!
    
    @IBOutlet weak var personalBestCard: UIView!
    
    @IBOutlet weak var progressBarCard: UIView!
    
    // 2. Persistent Model instance (The Source of Truth)
        var studyModel = StudyChartModel()
        
        // 3. Keep a reference to the hosting controller so we can update it
        private var hostingController: UIHostingController<BarChartView>?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            
            // Initial load of the chart
            refreshChartView()
        }
        
        // MARK: - Navigation
        
        // IMPORTANT: This connects the Log screen to this controller
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            // If you are using a Segue in Storyboard to show the Log Modal
            if let nav = segue.destination as? UINavigationController,
               let logVC = nav.topViewController as? LogProgressViewController {
                logVC.delegate = self // Setting the bridge
            }
        }
        
        // If you are presenting the modal programmatically via a button:
        @IBAction func addButtonPressed(_ sender: UIButton) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let nav = storyboard.instantiateViewController(withIdentifier: "LogNav") as? UINavigationController,
               let logVC = nav.topViewController as? LogProgressViewController {
                logVC.delegate = self
                present(nav, animated: true)
            }
        }

        // MARK: - Delegate Method
        
        // This runs when the user clicks 'Done' on the Log screen
    func didLogStudyTime(hours: Double, date: Date, subject: String?) {
        let minutes = hours * 60
        
        // Determine which time slot the log belongs to
        let hour = Calendar.current.component(.hour, from: date)
        let timeLabel: String
        if hour < 6 { timeLabel = "00" }
        else if hour < 12 { timeLabel = "06" }
        else if hour < 18 { timeLabel = "12" }
        else { timeLabel = "18" }
        
        DispatchQueue.main.async {
            if let lastPageIndex = self.studyModel.dailyHistory.indices.last {
                // Check if we already have a bar for this time slot
                if let index = self.studyModel.dailyHistory[lastPageIndex].firstIndex(where: { $0.label == timeLabel }) {
                    let existing = self.studyModel.dailyHistory[lastPageIndex][index]
                    // Update existing bar
                    self.studyModel.dailyHistory[lastPageIndex][index] = StudyData(
                        label: timeLabel,
                        focusMinutes: existing.focusMinutes + minutes,
                        extraMinutes: existing.extraMinutes
                    )
                } else {
                    // Create new bar for this slot
                    let newEntry = StudyData(label: timeLabel, focusMinutes: minutes, extraMinutes: 0)
                    self.studyModel.dailyHistory[lastPageIndex].append(newEntry)
                    // Sort to keep 00, 06, 12, 18 in order
                    self.studyModel.dailyHistory[lastPageIndex].sort { $0.label < $1.label }
                }
            }
            self.refreshChartView()
        }
    }

        // MARK: - UI Logic

        private func refreshChartView() {
            let isDaily = segmentControl.selectedSegmentIndex == 0
            
            // Create the SwiftUI View
            let chartView = BarChartView(model: studyModel, isShowingDaily: isDaily)
            
            if let host = hostingController {
                // If it already exists, just update the data (SwiftUI will animate)
                host.rootView = chartView
            } else {
                // If it's the first time, set up the hosting controller
                let host = UIHostingController(rootView: chartView)
                host.view.backgroundColor = .clear
                
                addChild(host)
                chartContainerView.addSubview(host.view)
                host.view.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    host.view.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
                    host.view.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
                    host.view.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
                    host.view.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
                ])
                
                host.didMove(toParent: self)
                hostingController = host
            }
        }

        private func setupUI() {
            chartContainerView.backgroundColor = .systemGray6
            chartContainerView.layer.cornerRadius = 20
            chartContainerView.clipsToBounds = true
            
            streaksCard.layer.cornerRadius = 16
            awardsCard.layer.cornerRadius = 16
            personalBestCard.layer.cornerRadius = 16
            progressBarCard.layer.cornerRadius = 16
        }
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        refreshChartView()
    }
}
   
