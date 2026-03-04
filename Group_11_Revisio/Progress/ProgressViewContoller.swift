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
    
    private let legendStackView = UIStackView()
        var studyModel = StudyChartModel()
        private var hostingController: UIHostingController<BarChartView>?
                    
    override func viewDidLoad() {
            super.viewDidLoad()
            
            // 🛑 ONE-TIME RESET:
            // Run once to start fresh today, then delete these 3 lines.
            UserDefaults.standard.removeObject(forKey: "user_current_streak")
            UserDefaults.standard.removeObject(forKey: "user_last_active_date")
            ProgressDataManager.shared.history = []
            
            setupUI()
            
            // This will now find .xpDidUpdate because of the extension in the other file
            NotificationCenter.default.addObserver(self, selector: #selector(refreshScreenData), name: .xpDidUpdate, object: nil)
            
            DispatchQueue.main.async {
                self.loadDataAndRefreshChart()
                self.updateStreakDisplay()
            }
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            // Checks today's date against last login
            ProgressDataManager.shared.updateDailyStreak()
            updateStreakDisplay()
        }
        
        @objc func refreshScreenData() {
            DispatchQueue.main.async {
                self.updateStreakDisplay()
                self.studyModel.updateChart(with: ProgressDataManager.shared.history)
            }
        }

        private func updateStreakDisplay() {
            let streak = ProgressDataManager.shared.currentStreak
            let suffix = (streak == 1) ? "Day" : "Days"
            streaksCountLabel.text = "\(streak) \(suffix)"
        }

    private func setupUI() {
        scrollView.contentInsetAdjustmentBehavior = .never
        view.backgroundColor = .black
        
        chartContainerView.backgroundColor = .systemGray6
        chartContainerView.layer.cornerRadius = 20
        chartContainerView.clipsToBounds = true
        
        // ✅ RESTORE CARD TITLES
        streaksCard.backgroundColor = .systemGray6
        streaksCard.layer.cornerRadius = 16
        streaksLabel.text = "Streaks"
        
        awardsCard.backgroundColor = .systemGray6
        awardsCard.layer.cornerRadius = 16
        awardsLabel.text = "Awards"
        
        monthNameLabel.text = "March Challenge"
        mainMonthBagdeImageView.image = UIImage(named: "awards_monthly_main")
    }
        private func loadDataAndRefreshChart() {
            hostingController?.view.removeFromSuperview()
            hostingController?.removeFromParent()
            
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
        }
    }
