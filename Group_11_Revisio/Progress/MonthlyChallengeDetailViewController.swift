//
//  MonthlyChallengeDetailViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 17/12/25.
//

import UIKit

class MonthlyChallengeDetailViewController: UIViewController {

    @IBOutlet weak var largeBadgeImageView: UIImageView!
    
    @IBOutlet weak var challengeTitleLabel: UILabel!
    
    @IBOutlet weak var challengeDescriptionLabel: UILabel!
    
    @IBOutlet weak var challengeProgressView: UIProgressView!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            navigationItem.title = "Awards"
            setupUI()
        }

        private func setupUI() {
            largeBadgeImageView.image = UIImage(named: "awards_monthly_main")
            challengeTitleLabel.text = "November Challenge"
            challengeDescriptionLabel.text = "Complete your monthly challenge when you gain 10 badges. You have won your monthly badge 1 time so far."
            challengeProgressView.progress = 0.3 // Example progress
        }
    }
