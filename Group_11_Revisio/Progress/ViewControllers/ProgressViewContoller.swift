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
    
    @IBOutlet weak var chartContainerView: UIView!
    @IBOutlet weak var hoursStudiedHeaderLabel: UILabel!
    
    @IBOutlet weak var achievementsHeaderLabel: UILabel!
    @IBOutlet weak var streaksCard: UIView!
    @IBOutlet weak var streaksLabel: UILabel!
    @IBOutlet weak var streaksCountLabel: UILabel!

    @IBOutlet weak var streaksDateLabel: UILabel!
    
    @IBOutlet weak var awardsCard: UIView!
    @IBOutlet weak var awardsLabel: UILabel!
    @IBOutlet weak var monthNameLabel: UILabel!
    @IBOutlet weak var mainMonthBagdeImageView: UIImageView!
    
            private let legendStackView = UIStackView()
            var studyModel = StudyChartModel()
            private var hostingController: UIHostingController<BarChartView>?

            override func viewDidLoad() {
                super.viewDidLoad()
                setupUI()
                setupTapGestures()

                NotificationCenter.default.addObserver(self, selector: #selector(refreshScreenData),
                                                       name: .xpDidUpdate, object: nil)
                DispatchQueue.main.async {
                    self.loadDataAndRefreshChart()
                    self.updateStreakDisplay()
                }
            }

            override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                updateStreakDisplay()
                // Reload chart from persisted history every time screen appears
                studyModel.updateChart(with: ProgressDataManager.shared.history)
            }

        //  Data refresh
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

                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yy"
                streaksDateLabel.text = formatter.string(from: Date())

                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "d MMM yyyy"
                monthNameLabel.text = "Today: \(displayFormatter.string(from: Date()))"
            }

            private func setupUI() {

                chartContainerView.backgroundColor = .systemGray6
                chartContainerView.layer.cornerRadius = 20
                chartContainerView.clipsToBounds = true

                hoursStudiedHeaderLabel.text = "Hours Studied"
                hoursStudiedHeaderLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)

                achievementsHeaderLabel.text = "Achievements"
                achievementsHeaderLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)

                streaksCard.backgroundColor = .systemGray6
                streaksCard.layer.cornerRadius = 16
                streaksLabel.text = "Streaks"
                streaksLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)

                awardsCard.backgroundColor = .systemGray6
                awardsCard.layer.cornerRadius = 16
                awardsLabel.text = "Awards"
                awardsLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)

                monthNameLabel.text = "March Challenge"
                mainMonthBagdeImageView.image = UIImage(named: "awards_monthly_main")
            }

        // Navigation Gestures & Buttons

        private func setupTapGestures() {
            streaksCard.isUserInteractionEnabled = true
            awardsCard.isUserInteractionEnabled  = true

            // Overlay transparent button for Streaks Chevron (44x44 Hit Test Area)
            let streaksButton = UIButton(type: .system)
            streaksButton.backgroundColor = .clear
            streaksButton.showsTouchWhenHighlighted = true
            streaksButton.translatesAutoresizingMaskIntoConstraints = false
            streaksButton.addTarget(self, action: #selector(streaksChevronTapped), for: .touchUpInside)
            streaksCard.addSubview(streaksButton)
            
            NSLayoutConstraint.activate([
                streaksButton.trailingAnchor.constraint(equalTo: streaksCard.trailingAnchor),
                streaksButton.topAnchor.constraint(equalTo: streaksCard.topAnchor),
                streaksButton.widthAnchor.constraint(equalToConstant: 44),
                streaksButton.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            // Overlay transparent button for Awards Chevron (44x44 Hit Test Area)
            let awardsButton = UIButton(type: .system)
            awardsButton.backgroundColor = .clear
            awardsButton.showsTouchWhenHighlighted = true
            awardsButton.translatesAutoresizingMaskIntoConstraints = false
            awardsButton.addTarget(self, action: #selector(awardsChevronTapped), for: .touchUpInside)
            awardsCard.addSubview(awardsButton)
            
            NSLayoutConstraint.activate([
                awardsButton.trailingAnchor.constraint(equalTo: awardsCard.trailingAnchor),
                awardsButton.topAnchor.constraint(equalTo: awardsCard.topAnchor),
                awardsButton.widthAnchor.constraint(equalToConstant: 44),
                awardsButton.heightAnchor.constraint(equalToConstant: 44)
            ])
        }

        @objc private func streaksChevronTapped() {
            let vc = StreaksCalendarViewController()
            navigationController?.pushViewController(vc, animated: true)
        }

        @objc private func awardsChevronTapped() {
            let storyboard = UIStoryboard(name: "Progress", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "AwardsViewController")
            navigationController?.pushViewController(vc, animated: true)
        }

        // Chart
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
