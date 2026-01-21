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
            navigationItem.title = "Monthly Challenge"
            setupUI()
        }

    private func setupUI() {
           
            largeBadgeImageView.image = UIImage(named: "awards_monthly_main")
            largeBadgeImageView.contentMode = .scaleAspectFit
            
            challengeTitleLabel.text = "January Challenge"
            challengeTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
            challengeTitleLabel.textColor = .label
            challengeTitleLabel.textAlignment = .center
            
            challengeDescriptionLabel.text = "Complete your monthly challenge when you gain 10 badges. You have won your monthly badge 1 time so far."
            challengeDescriptionLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
            challengeDescriptionLabel.textColor = .secondaryLabel
            challengeDescriptionLabel.textAlignment = .center
            challengeDescriptionLabel.numberOfLines = 0
            
            challengeProgressView.progress = 0.1
            challengeProgressView.progressTintColor = .systemBlue
            challengeProgressView.trackTintColor = .systemGray5
            challengeProgressView.transform = challengeProgressView.transform.scaledBy(x: 1, y: 2.0)
            challengeProgressView.layer.cornerRadius = 4
            challengeProgressView.clipsToBounds = true
        }
    }
    
