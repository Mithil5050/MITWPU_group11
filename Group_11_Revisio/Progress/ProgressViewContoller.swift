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
    
    // MARK: - Private state

        private let legendStackView = UIStackView()
        var studyModel = StudyChartModel()
        private var hostingController: UIHostingController<BarChartView>?


        // MARK: - Lifecycle

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
        }

        // MARK: - Data refresh

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

        // MARK: - UI Setup

        private func setupUI() {
            scrollView.contentInsetAdjustmentBehavior = .never
            view.backgroundColor = .black

            chartContainerView.backgroundColor = .systemGray6
            chartContainerView.layer.cornerRadius = 20
            chartContainerView.clipsToBounds = true

            hoursStudiedHeaderLabel.text = "Hours Studied"
            hoursStudiedHeaderLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)

            achievementsHeaderLabel.text = "Achievements"
            achievementsHeaderLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)

            // Streaks card
            streaksCard.backgroundColor = .systemGray6
            streaksCard.layer.cornerRadius = 16
            streaksLabel.text = "Streaks"
            streaksLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)

            // Awards card
            awardsCard.backgroundColor = .systemGray6
            awardsCard.layer.cornerRadius = 16
            awardsLabel.text = "Awards"
            awardsLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)

            monthNameLabel.text = "March Challenge"
            mainMonthBagdeImageView.image = UIImage(named: "awards_monthly_main")
        }

        // MARK: - Tap Gestures

        private func setupTapGestures() {
            streaksCard.isUserInteractionEnabled = true
            awardsCard.isUserInteractionEnabled  = true

            streaksCard.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(streaksCardTapped))
            )
            awardsCard.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(awardsCardTapped))
            )
        }

        @objc private func streaksCardTapped() {
            let vc = StreaksCalendarViewController()
            navigationController?.pushViewController(vc, animated: true)
        }

        @objc private func awardsCardTapped() {
            let vc = AwardsViewController(nibName: "AwardsViewController", bundle: nil)
            navigationController?.pushViewController(vc, animated: true)
        }

        // MARK: - Chart

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

























