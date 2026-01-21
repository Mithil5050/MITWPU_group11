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
    
    @IBOutlet weak var personalBadgeImageView: UIImageView!
    
    @IBOutlet weak var mainMonthBagdeImageView: UIImageView!
    
    var studyModel = StudyChartModel()
        private var hostingController: UIHostingController<BarChartView>?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()

            // initial load
            loadDataAndRefreshChart()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            loadDataAndRefreshChart()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            scrollView.contentInsetAdjustmentBehavior = .never
            let contentHeight = stackView.frame.height
            scrollView.contentSize = CGSize(width: view.frame.width, height: contentHeight)
        }
        
        private func loadDataAndRefreshChart() {
        
            ProgressDataManager.shared.loadInitialData()
            
           // map logs
            studyModel.updateChart(with: ProgressDataManager.shared.history)
    
            refreshChartView()
        }
    
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if let nav = segue.destination as? UINavigationController,
               let logVC = nav.topViewController as? LogProgressViewController {
                logVC.delegate = self
            }
        }

       
        func didLogStudyTime(hours: Double, date: Date, subject: String?) {
            DispatchQueue.main.async {
                self.loadDataAndRefreshChart()
            }
        }

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

            personalBadgeImageView.image = UIImage(named: "best subject")
            
            mainMonthBagdeImageView.image = UIImage(named: "awards_monthly_main")
            
            streaksCard.layer.cornerRadius = 16
            awardsCard.layer.cornerRadius = 16
            personalBestCard.layer.cornerRadius = 16
            progressBarCard.layer.cornerRadius = 16
        }
    
        @IBAction func segmentChanged(_ sender: UISegmentedControl) {
            refreshChartView()
        }
    }
