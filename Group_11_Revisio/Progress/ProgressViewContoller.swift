//
//  ProgressViewContoller.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 27/11/25.
//

import UIKit

class ProgressViewContoller: UIViewController {

    @IBOutlet weak var hoursGraphView: UIView!
    var chart = BarGraphView()
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
                  chart.values = [2, 4, 3, 6, 7, 5]
              } else {
                  chart.values = [4, 7, 6, 10, 5, 9]
              }
          }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Set up chart
           chart.translatesAutoresizingMaskIntoConstraints = false
           chart.backgroundColor = .clear
           chart.values = [4, 7, 6, 10, 5, 9]   // initial values

        hoursGraphView.addSubview(chart)

           NSLayoutConstraint.activate([
               chart.leadingAnchor.constraint(equalTo:hoursGraphView.leadingAnchor, constant: 12),
               chart.trailingAnchor.constraint(equalTo: hoursGraphView.trailingAnchor, constant: -12),
               chart.topAnchor.constraint(equalTo: hoursGraphView.topAnchor, constant: 12),
               chart.bottomAnchor.constraint(equalTo: hoursGraphView.bottomAnchor, constant: -12)
           ])
       }
    
    @IBAction func awardsButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowAwardsPage", sender: nil)
    }
    
//       This actually places the chart inside the container.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


