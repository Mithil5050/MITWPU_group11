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
    
    @IBOutlet weak var streaksCard: UIView!
    @IBOutlet weak var streaksLabel: UILabel!
    @IBOutlet weak var streaksCountLabel: UILabel!
    
    @IBOutlet weak var awardsCard: UIView!
    @IBOutlet weak var awardsLabel: UILabel!
    @IBOutlet weak var monthNameLabel: UILabel!
    @IBOutlet weak var mainMonthBagdeImageView: UIImageView!
    
        // Legend Container for the chart
        private let legendStackView = UIStackView()
        var studyModel = StudyChartModel()
        private var hostingController: UIHostingController<BarChartView>?
                    
        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            
            // Listen for data updates to refresh the streak and chart
            // We keep this because XP updates often coincide with Streak updates
            NotificationCenter.default.addObserver(self, selector: #selector(refreshScreenData), name: .xpDidUpdate, object: nil)
            
            DispatchQueue.main.async {
                ProgressDataManager.shared.loadInitialData()
                self.loadDataAndRefreshChart()
                self.updateStreakDisplay()
            }
        }
        
        @objc func refreshScreenData() {
            DispatchQueue.main.async {
                self.updateStreakDisplay()
                // Reload chart data from history if it has changed
                self.studyModel.updateChart(with: ProgressDataManager.shared.history)
            }
        }

        private func loadDataAndRefreshChart() {
            // Clear old chart if exists
            hostingController?.view.removeFromSuperview()
            hostingController?.removeFromParent()
            
            // Refresh the model with the latest history before creating the view
            studyModel.updateChart(with: ProgressDataManager.shared.history)
            
            let chartView = BarChartView(model: studyModel)
            let hostingVC = UIHostingController(rootView: chartView)
            hostingVC.view.backgroundColor = .clear
            
            addChild(hostingVC)
            chartContainerView.addSubview(hostingVC.view)
            hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                hostingVC.view.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
                hostingVC.view.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
                hostingVC.view.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
                hostingVC.view.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
            ])
            
            hostingVC.didMove(toParent: self)
            self.hostingController = hostingVC
            
            setupLegend()
        }
        
        private func updateStreakDisplay() {
            let streak = ProgressDataManager.shared.currentStreak
            // Adding a plural check for "Day/Days" to make it look professional
            let suffix = (streak == 1) ? "Day" : "Days"
            streaksCountLabel.text = "\(streak) \(suffix)"
        }

        private func setupUI() {
            scrollView.contentInsetAdjustmentBehavior = .never
            view.backgroundColor = .black
            
            chartContainerView.backgroundColor = .systemGray6
            chartContainerView.layer.cornerRadius = 20
            chartContainerView.clipsToBounds = true
            
            // ✅ XP Card setup logic removed to match storyboard changes
            
            streaksCard.backgroundColor = .systemGray6
            streaksCard.layer.cornerRadius = 16
            streaksLabel.text = "Streaks"
            
            awardsCard.backgroundColor = .systemGray6
            awardsCard.layer.cornerRadius = 16
            awardsLabel.text = "Awards"
            
            monthNameLabel.text = "January Challenge"
            mainMonthBagdeImageView.image = UIImage(named: "awards_monthly_main")
        }
        
        private func setupLegend() {
            legendStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            legendStackView.axis = .horizontal
            legendStackView.spacing = 16
            legendStackView.alignment = .center
            
            let studyLegend = createLegendItem(color: .blue, text: "Study")
            let gamesLegend = createLegendItem(color: UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0), text: "Games")
            
            legendStackView.addArrangedSubview(studyLegend)
            legendStackView.addArrangedSubview(gamesLegend)
            
            if let chartIndex = stackView.arrangedSubviews.firstIndex(of: chartContainerView) {
                stackView.insertArrangedSubview(legendStackView, at: chartIndex + 1)
                legendStackView.isLayoutMarginsRelativeArrangement = true
                legendStackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 12, right: 16)
            }
        }
        
        private func createLegendItem(color: UIColor, text: String) -> UIView {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 4
            
            let dot = UIView()
            dot.backgroundColor = color
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 12)
            label.textColor = .secondaryLabel
            
            stack.addArrangedSubview(dot)
            stack.addArrangedSubview(label)
            return stack
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            let contentHeight = stackView.frame.height
            scrollView.contentSize = CGSize(width: view.frame.width, height: contentHeight + 40)
        }
    }
