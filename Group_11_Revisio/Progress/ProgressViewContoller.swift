//
//  ProgressViewContoller.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 27/11/25.
//

import UIKit
import SwiftUI
import Charts

class ProgressViewContoller: UIViewController {
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var chartContainerView: UIView!
    
    @IBOutlet weak var xpCard: UIView!
    @IBOutlet weak var xpImageView: UIImageView!
    @IBOutlet weak var xpLevelLabel: UILabel!
    @IBOutlet weak var xpValueLabel: UILabel!
    @IBOutlet weak var xpProgressBar: UIProgressView!
    
    @IBOutlet weak var streaksCard: UIView!
    @IBOutlet weak var streaksLabel: UILabel!
    @IBOutlet weak var streaksCountLabel: UILabel!
    
    @IBOutlet weak var awardsCard: UIView!
    @IBOutlet weak var awardsLabel: UILabel!
    @IBOutlet weak var monthNameLabel: UILabel!
    @IBOutlet weak var progressBarCard: UIView!
    @IBOutlet weak var mainMonthBagdeImageView: UIImageView!
    
    // MARK: - Properties
        var studyModel = StudyChartModel()
        private var hostingController: UIHostingController<BarChartView>?
                
        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            
            // Initial data load for the chart
            loadDataAndRefreshChart()
            
            // Listen for XP updates while the app is running to refresh the UI instantly
            NotificationCenter.default.addObserver(self, selector: #selector(updateGamificationUI), name: .xpDidUpdate, object: nil)
        }
                
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            // We call this here to ensure labels are fresh every time the user switches tabs
            updateGamificationUI()
            
            // If data changes frequently, you can also trigger a chart refresh here
            studyModel.updateChart(with: ProgressDataManager.shared.history)
        }
                
        // MARK: - UI Updates
        @objc private func updateGamificationUI() {
            let manager = ProgressDataManager.shared
            
            // 1. Update XP and Level Labels
            xpLevelLabel?.text = "Level \(manager.currentLevel)"
            xpValueLabel?.text = "\(manager.totalXP) XP"
            
            // 2. Update Streak Label
            let streakValue = manager.currentStreak
            let suffix = (streakValue == 1) ? "Day" : "Days"
            streaksCountLabel?.text = "\(streakValue) \(suffix)"
           
            
            // 3. Update progress bar percentage (0.0 to 1.0)
            // Formula calculates how far user is between current level floor and next level ceiling
            let levelFloor = pow(Double(manager.currentLevel) / 0.1, 2)
            let levelCeiling = pow(Double(manager.currentLevel + 1) / 0.1, 2)
            
            let diff = levelCeiling - levelFloor
            if diff > 0 {
                let progress = Float((Double(manager.totalXP) - levelFloor) / diff)
                xpProgressBar?.setProgress(progress, animated: true)
            }
            
            // Visual indicator: Highlight streak card if active
            streaksCard.layer.borderWidth = manager.currentStreak > 0 ? 1.5 : 0
            streaksCard.layer.borderColor = UIColor.systemOrange.cgColor
        }

        private func loadDataAndRefreshChart() {
            // Force the manager to load JSON history
            ProgressDataManager.shared.loadInitialData()
            
            // Pass current history to the SwiftUI Chart model
            let logs = ProgressDataManager.shared.history
            studyModel.updateChart(with: logs)
            
            refreshChartView()
        }

        private func refreshChartView() {
            let chartView = BarChartView(model: studyModel)
            
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
            // Layout and Scrolling
            scrollView.contentInsetAdjustmentBehavior = .never
            
            // Card Styling
            chartContainerView.backgroundColor = .systemGray6
            chartContainerView.layer.cornerRadius = 20
            chartContainerView.clipsToBounds = true
            
            xpCard.backgroundColor = .systemGray6
            xpCard.layer.cornerRadius = 16
            
            streaksCard.backgroundColor = .systemGray6
            streaksCard.layer.cornerRadius = 16
            streaksLabel.text = "Streaks"
            
            awardsCard.backgroundColor = .systemGray6
            awardsCard.layer.cornerRadius = 16
            awardsLabel.text = "Awards"
            
            monthNameLabel.text = "January Challenge"
            mainMonthBagdeImageView.image = UIImage(named: "awards_monthly_main")
            
            progressBarCard.layer.cornerRadius = 16
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            // Ensure the scrollview content size matches the total height of the stack
            let contentHeight = stackView.frame.height
            scrollView.contentSize = CGSize(width: view.frame.width, height: contentHeight + 40)
        }
    }
