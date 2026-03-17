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
                let target = 10
                let earned = ProgressDataManager.shared.earnedBadgeCount
                let monthName = currentMonthName()
                let completed = earned >= target
     
                largeBadgeImageView.contentMode = .scaleAspectFit
                largeBadgeImageView.image = UIImage(named: "awards_monthly_main")
                largeBadgeImageView.alpha = completed ? 1.0 : 0.5
     
                challengeTitleLabel.text = monthName
                challengeTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
                challengeTitleLabel.textColor = .label
                challengeTitleLabel.textAlignment = .center
     
                if completed {
                    challengeDescriptionLabel.text = "You've completed the \(monthName) Challenge! You earned \(earned) badge\(earned == 1 ? "" : "s") this month. 🎉"
                } else {
                    let remaining = target - earned
                    challengeDescriptionLabel.text = "Earn \(remaining) more badge\(remaining == 1 ? "" : "s") to complete the \(monthName) Challenge."
                }
                challengeDescriptionLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
                challengeDescriptionLabel.textColor = .secondaryLabel
                challengeDescriptionLabel.textAlignment = .center
                challengeDescriptionLabel.numberOfLines = 0
     
                let progress = min(Float(earned) / Float(target), 1.0)
                challengeProgressView.progressTintColor = completed ? .systemGreen : .systemBlue
                challengeProgressView.trackTintColor = .systemGray5
                challengeProgressView.transform = challengeProgressView.transform.scaledBy(x: 1, y: 2.0)
                challengeProgressView.layer.cornerRadius = 4
                challengeProgressView.clipsToBounds = true
                challengeProgressView.setProgress(0, animated: false)
                UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut) {
                    self.challengeProgressView.setProgress(progress, animated: true)
                }
            }
     
        private func currentMonthName() -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            return formatter.string(from: Date())
        }
        }
        
     
