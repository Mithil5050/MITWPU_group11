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
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var chartContainerView: UIView!
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var streaksCard: UIView!
    
    @IBOutlet weak var awardsCard: UIView!
    
    @IBOutlet weak var personalBestCard: UIView!
    
    @IBOutlet weak var progressBarCard: UIView!
    
    
    // MARK: - Properties
        var studyModel = StudyChartModel()
        private var hostingController: UIHostingController<BarChartView>?
        
        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            
            // Initial load from DataManager (which reads your JSON)
            loadDataAndRefreshChart()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            // Refresh every time the screen appears to catch deletions/edits
            loadDataAndRefreshChart()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            scrollView.contentInsetAdjustmentBehavior = .never
            let contentHeight = stackView.frame.height
            scrollView.contentSize = CGSize(width: view.frame.width, height: contentHeight)
        }
        
        // MARK: - Data Management
        private func loadDataAndRefreshChart() {
            // 1. Tell DataManager to load (from Storage or JSON)
            ProgressDataManager.shared.loadInitialData()
            
            // 2. Map the logs into the chart's bars
            studyModel.updateChart(with: ProgressDataManager.shared.history)
            
            // 3. Update the UI
            refreshChartView()
        }
        
        // MARK: - Navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if let nav = segue.destination as? UINavigationController,
               let logVC = nav.topViewController as? LogProgressViewController {
                logVC.delegate = self
            }
        }

        // MARK: - Delegate Method
        /// This now just triggers a full reload from the DataManager
        /// ensuring the Chart and List always match exactly.
        func didLogStudyTime(hours: Double, date: Date, subject: String?) {
            DispatchQueue.main.async {
                self.loadDataAndRefreshChart()
            }
        }

        // MARK: - UI Logic
        private func refreshChartView() {
            let isDaily = segmentControl.selectedSegmentIndex == 0
            let chartView = BarChartView(model: studyModel, isShowingDaily: isDaily)
            
            if let host = hostingController {
                host.rootView = chartView
            } else {
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
            scrollView.isScrollEnabled = true
            scrollView.alwaysBounceVertical = true
            
            chartContainerView.backgroundColor = .systemGray6
            chartContainerView.layer.cornerRadius = 20
            chartContainerView.clipsToBounds = true
            
            streaksCard.layer.cornerRadius = 16
            awardsCard.layer.cornerRadius = 16
            personalBestCard.layer.cornerRadius = 16
            progressBarCard.layer.cornerRadius = 16
        }
    
    
//    // MARK: - Properties
//        var studyModel = StudyChartModel()
//        private var hostingController: UIHostingController<BarChartView>?
//        
//        // MARK: - Lifecycle
//        override func viewDidLoad() {
//            super.viewDidLoad()
//            setupUI()
//            refreshChartView()
//        }
//        override func viewDidLayoutSubviews() {
//            super.viewDidLayoutSubviews()
//            
//            // Disable scroll view's automatic content inset adjustment if needed
//            scrollView.contentInsetAdjustmentBehavior = .never
//            
//            // Force the content size to match the stack view's height
//            let contentHeight = stackView.frame.height
//            scrollView.contentSize = CGSize(width: view.frame.width, height: contentHeight)
//        }
//        
//        // MARK: - Navigation
//        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//            if let nav = segue.destination as? UINavigationController,
//               let logVC = nav.topViewController as? LogProgressViewController {
//                logVC.delegate = self
//            }
//        }
//    
//
//        // MARK: - Delegate Method
//        func didLogStudyTime(hours: Double, date: Date, subject: String?) {
//            let minutes = hours * 60
//            let hour = Calendar.current.component(.hour, from: date)
//            
//            let timeLabel: String
//            if hour < 6 { timeLabel = "00" }
//            else if hour < 12 { timeLabel = "06" }
//            else if hour < 18 { timeLabel = "12" }
//            else { timeLabel = "18" }
//            
//            DispatchQueue.main.async {
//                if let lastPageIndex = self.studyModel.dailyHistory.indices.last {
//                    if let index = self.studyModel.dailyHistory[lastPageIndex].firstIndex(where: { $0.label == timeLabel }) {
//                        let existing = self.studyModel.dailyHistory[lastPageIndex][index]
//                        self.studyModel.dailyHistory[lastPageIndex][index] = StudyData(
//                            label: timeLabel,
//                            focusMinutes: existing.focusMinutes + minutes,
//                            extraMinutes: existing.extraMinutes
//                        )
//                    } else {
//                        let newEntry = StudyData(label: timeLabel, focusMinutes: minutes, extraMinutes: 0)
//                        self.studyModel.dailyHistory[lastPageIndex].append(newEntry)
//                        self.studyModel.dailyHistory[lastPageIndex].sort { $0.label < $1.label }
//                    }
//                }
//                self.refreshChartView()
//            }
//        }
//
//        // MARK: - UI Logic
//        private func refreshChartView() {
//            let isDaily = segmentControl.selectedSegmentIndex == 0
//            let chartView = BarChartView(model: studyModel, isShowingDaily: isDaily)
//            
//            if let host = hostingController {
//                host.rootView = chartView
//            } else {
//                let host = UIHostingController(rootView: chartView)
//                host.view.backgroundColor = .clear
//                
//                addChild(host)
//                chartContainerView.addSubview(host.view)
//                host.view.translatesAutoresizingMaskIntoConstraints = false
//                
//                NSLayoutConstraint.activate([
//                    host.view.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
//                    host.view.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
//                    host.view.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
//                    host.view.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
//                ])
//                
//                host.didMove(toParent: self)
//                hostingController = host
//            }
//        }
//
//        private func setupUI() {
//            // Setup ScrollView behaviors
//            scrollView.isScrollEnabled = true
//            scrollView.alwaysBounceVertical = true
//            
//            chartContainerView.backgroundColor = .systemGray6
//            chartContainerView.layer.cornerRadius = 20
//            chartContainerView.clipsToBounds = true
//            
//            streaksCard.layer.cornerRadius = 16
//            awardsCard.layer.cornerRadius = 16
//            personalBestCard.layer.cornerRadius = 16
//            progressBarCard.layer.cornerRadius = 16
//        }
        
        @IBAction func segmentChanged(_ sender: UISegmentedControl) {
            refreshChartView()
        }
    }
