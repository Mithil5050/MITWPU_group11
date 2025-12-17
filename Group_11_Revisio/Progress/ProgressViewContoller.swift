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
    
    
    private var hostingController: UIHostingController<BarChartView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        showChart(data: StudyChartModel.dayData)
    }

    private func setupUI() {
        chartContainerView.backgroundColor = .systemGray6
        chartContainerView.clipsToBounds = true
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            showChart(data: StudyChartModel.dayData)
    
        } else {
            showChart(data: StudyChartModel.weekData) 
        }
    }

  private func showChart(data: [StudyData]) {

      hostingController?.view.removeFromSuperview()
      hostingController?.removeFromParent()

      let chartView = BarChartView(data: data)
      let host = UIHostingController(rootView: chartView)

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
