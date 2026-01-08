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
    
    
    @IBOutlet weak var chartContainerView: UIView!
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var streaksCard: UIView!
    
    @IBOutlet weak var awardsCard: UIView!
    
    @IBOutlet weak var personalBestCard: UIView!
    
    @IBOutlet weak var progressBarCard: UIView!
    
    private var hostingController: UIHostingController<BarChartView>?
    
    override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            // Load Today's Page (part of dailyHistory)
            showChart(history: StudyChartModel.dailyHistory)
        }

        private func showChart(history: [[StudyData]]) {
            hostingController?.view.removeFromSuperview()
            hostingController?.removeFromParent()

            let chartView = BarChartView(history: history)
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

        private func setupUI() {
            chartContainerView.backgroundColor = .systemGray6
            chartContainerView.clipsToBounds = true
            
            // Ensure your layer settings are not commented out
            streaksCard.layer.cornerRadius = 16
            awardsCard.layer.cornerRadius = 16
            personalBestCard.layer.cornerRadius = 16
            progressBarCard.layer.cornerRadius = 16
        }
    
    //        setupUI()
    //        showChart(data: StudyChartModel.dayData)
    //    }
    //    
    //    private func setupUI() {
    //        chartContainerView.backgroundColor = .systemGray6
    //        chartContainerView.clipsToBounds = true
    //        
    //        streaksCard.layer.cornerRadius = 16
    //        awardsCard.layer.cornerRadius = 16
    //        personalBestCard.layer.cornerRadius = 16
    //        progressBarCard.layer.cornerRadius = 16
    //    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // Pass the full 2D array for daily scrolling
            showChart(history: StudyChartModel.dailyHistory)
        } else {
            // Pass the full 2D array for weekly scrolling
            showChart(history: StudyChartModel.weeklyHistory)
        }
    }
}
   
