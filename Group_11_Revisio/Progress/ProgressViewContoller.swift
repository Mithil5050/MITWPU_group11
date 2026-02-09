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
    @IBOutlet weak var mainMonthBagdeImageView: UIImageView!
    
    // Legend Container
        private let legendStackView = UIStackView()
        
        var studyModel = StudyChartModel()
        private var hostingController: UIHostingController<BarChartView>?
                
        // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Move heavy data loading to a slight delay or a safer lifecycle hook
        DispatchQueue.main.async {
            ProgressDataManager.shared.loadInitialData()
            self.loadDataAndRefreshChart()
        }
    }
                
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            updateGamificationUI()
            studyModel.updateChart(with: ProgressDataManager.shared.history)
        }
                
        // MARK: - UI Updates
        @objc private func updateGamificationUI() {
            let manager = ProgressDataManager.shared
            
            xpLevelLabel?.text = "Level \(manager.currentLevel)"
            xpValueLabel?.text = "\(manager.totalXP) XP"
            
            let streakValue = manager.currentStreak
            let suffix = (streakValue == 1) ? "Day" : "Days"
            streaksCountLabel?.text = "\(streakValue) \(suffix)"
            
            let levelFloor = pow(Double(manager.currentLevel) / 0.1, 2)
            let levelCeiling = pow(Double(manager.currentLevel + 1) / 0.1, 2)
            
            let diff = levelCeiling - levelFloor
            if diff > 0 {
                let progress = Float((Double(manager.totalXP) - levelFloor) / diff)
                xpProgressBar?.setProgress(progress, animated: true)
            }
            
            streaksCard.layer.borderWidth = manager.currentStreak > 0 ? 1.5 : 0
            streaksCard.layer.borderColor = UIColor.systemOrange.cgColor
        }

        private func loadDataAndRefreshChart() {
            ProgressDataManager.shared.loadInitialData()
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

        // MARK: - Legend Setup
        private func setupLegend() {
            legendStackView.axis = .horizontal
            legendStackView.distribution = .equalSpacing
            legendStackView.alignment = .center
            legendStackView.spacing = 8
            legendStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Define Categories and custom colors
            let categories = [
                ("Flashcards", UIColor(red: 0.57, green: 0.76, blue: 0.94, alpha: 1.0)),
                ("Quizzes", UIColor(red: 0.53, green: 0.84, blue: 0.41, alpha: 1.0)),
                ("Cheatsheet", UIColor(red: 0.54, green: 0.22, blue: 0.96, alpha: 0.5)),
                ("Notes", UIColor(red: 1.00, green: 0.77, blue: 0.27, alpha: 0.75))
            ]
            
            for (name, color) in categories {
                let itemStack = UIStackView()
                itemStack.axis = .horizontal
                itemStack.spacing = 4
                
                let indicator = UIView()
                indicator.backgroundColor = color
                indicator.layer.cornerRadius = 4
                indicator.translatesAutoresizingMaskIntoConstraints = false
                indicator.widthAnchor.constraint(equalToConstant: 8).isActive = true
                indicator.heightAnchor.constraint(equalToConstant: 8).isActive = true
                
                let label = UILabel()
                label.text = name
                label.font = .systemFont(ofSize: 10, weight: .bold)
                label.textColor = color // Word colored according to stack
                
                itemStack.addArrangedSubview(indicator)
                itemStack.addArrangedSubview(label)
                legendStackView.addArrangedSubview(itemStack)
            }
            
            // Add to stackView below chartContainerView
            if let chartIndex = stackView.arrangedSubviews.firstIndex(of: chartContainerView) {
                stackView.insertArrangedSubview(legendStackView, at: chartIndex + 1)
                
                // Add padding to the legend
                legendStackView.isLayoutMarginsRelativeArrangement = true
                legendStackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 12, right: 16)
            }
        }

        private func setupUI() {
            scrollView.contentInsetAdjustmentBehavior = .never
            
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
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            let contentHeight = stackView.frame.height
            scrollView.contentSize = CGSize(width: view.frame.width, height: contentHeight + 40)
        }
    }
