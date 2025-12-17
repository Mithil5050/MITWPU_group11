//
//  ResultsViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 12/12/25.
//

import UIKit

class ResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    

    // The result to display on this screen
    var finalResult : FinalQuizResult?
    private var isGaugePositioned = false
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var gaugeContainerView: UIView!
    
    @IBOutlet weak var detailTableView: UITableView!
    
    @IBOutlet weak var retakeButton: UIButton!
    
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
            detailTableView.isScrollEnabled = false
            detailTableView.rowHeight = 55
           
            detailTableView.dataSource = self
            detailTableView.delegate = self

        detailTableView.dataSource = self
        detailTableView.delegate = self
        displayResults()
       
    }
    
    
    @IBAction func retakeButtonTapped(_ sender: Any) {
        guard let navigationController = self.navigationController else {
                return
            }
            
           
            for viewController in navigationController.viewControllers {
                
                if viewController.isKind(of: InstructionViewController.self) {
                
                    navigationController.popToViewController(viewController, animated: true)
                    return
                }
            }
            
           
            navigationController.popToRootViewController(animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    func displayResults() {
        guard let results = self.finalResult else {
            scoreLabel.text = "N/A"
            return
        }
        
        title = "Score"
        scoreLabel.text = "\(results.finalScore)/\(results.totalQuestions)"
        drawScoreGauge(score: results.finalScore, total: results.totalQuestions)
        
        detailTableView.reloadData()
    }
    
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? "00:00"
    }
    func setupScoreLabelPosition() {
       
        scoreLabel.translatesAutoresizingMaskIntoConstraints = true
        
       
        let centerX = gaugeContainerView.bounds.midX
        let centerY = gaugeContainerView.bounds.midY
        
        
        let labelWidth: CGFloat = 120
        let labelHeight: CGFloat = 40
        
        
        scoreLabel.frame = CGRect(
            x: centerX - (labelWidth / 2),
            y: centerY - (labelHeight / 2),
            width: labelWidth,
            height: labelHeight
        )
        
        
        scoreLabel.textAlignment = .center
        scoreLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        scoreLabel.textColor = .black // Make sure the color is visible
    }

    // MARK: - DETAIL TABLE VIEW Data Source & Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
        
        if indexPath.row == 0 {
            let timeString = formatTimeInterval(finalResult?.timeElapsed ?? 0)
            cell.textLabel?.text = "Time Taken"
            cell.detailTextLabel?.text = timeString
            cell.accessoryType = .none
            cell.selectionStyle = .none
            
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "See Summary"
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 1 {
            guard finalResult != nil else { return }
            performSegue(withIdentifier: "ShowReviewDetail", sender: finalResult!.details)
        }
    }
    

    func drawScoreGauge(score: Int, total: Int) {
        
        gaugeContainerView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let percentage = CGFloat(score) / CGFloat(total)
        let center = CGPoint(x: gaugeContainerView.bounds.midX, y: gaugeContainerView.bounds.midY)
        let radius: CGFloat = 80
        let startAngle: CGFloat = -.pi / 2
        let endAngle: CGFloat = startAngle + (2 * .pi * percentage)
        
        
        let trackPath = UIBezierPath(arcCenter: center,
                                     radius: radius,
                                     startAngle: 0,
                                     endAngle: 2 * .pi,
                                     clockwise: true)
        
        let trackLayer = CAShapeLayer()
        trackLayer.path = trackPath.cgPath
        trackLayer.strokeColor = UIColor.systemGray4.cgColor
        trackLayer.lineWidth = 15
        trackLayer.fillColor = UIColor.clear.cgColor
        
        gaugeContainerView.layer.addSublayer(trackLayer)
        
        
        let scorePath = UIBezierPath(arcCenter: center,
                                     radius: radius,
                                     startAngle: startAngle,
                                     endAngle: endAngle,
                                     clockwise: true)
        
        let scoreLayer = CAShapeLayer()
        scoreLayer.path = scorePath.cgPath
        scoreLayer.strokeColor = UIColor.systemBlue.cgColor
        scoreLayer.lineWidth = 15
        scoreLayer.lineCap = .round
        scoreLayer.fillColor = UIColor.clear.cgColor
        
        gaugeContainerView.layer.addSublayer(scoreLayer)
        
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 1.0
        scoreLayer.add(animation, forKey: "scoreAnimation")
    }
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if segue.identifier == "ShowReviewDetail" {
            if let reviewVC = segue.destination as? ReviewDetailViewController,
               let details = sender as? [QuestionResultDetail] {
                
                reviewVC.allQuestionDetails = details
          }
                 }
    }
}

 // Placeholder to satisfy compiler if the real ReviewDetailViewController exists elsewhere.
//class ReViewController: UIViewController {
//    var allQuestionDetails: [ResultsViewController.QuestionResultDetail] = []
//}
