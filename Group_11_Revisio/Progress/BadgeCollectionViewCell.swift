//
//  BadgeCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import UIKit

class BadgeCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var badgeCardView: UIView!
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var badgeTitleLabel: UILabel!
    @IBOutlet weak var badgeProgressBar: UIProgressView!
    @IBOutlet weak var badgeDetailLabel: UILabel!
    
    
    override func awakeFromNib() {
            super.awakeFromNib()
            setupUI()
        }
        
        private func setupUI() {
            // Transparent grey card style
            badgeCardView.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
            badgeCardView.layer.cornerRadius = 12
            badgeCardView.clipsToBounds = true
            
            badgeTitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
            badgeTitleLabel.textColor = .white
            badgeTitleLabel.textAlignment = .center
            
            badgeDetailLabel.font = UIFont.systemFont(ofSize: 9, weight: .medium)
            badgeDetailLabel.textColor = .systemGray
            badgeDetailLabel.textAlignment = .center
            
            // Prepare image view for lock placeholders
            badgeImageView.contentMode = .scaleAspectFit
            badgeImageView.tintColor = .systemGray
        }
                
        func configure(with badge: Badge, forSection section: AwardsSection) {
            badgeTitleLabel.text = badge.title
            
            // FOR NOW: Reserve space with a lock icon
            badgeImageView.image = UIImage(systemName: "lock.fill")
            badgeImageView.alpha = 0.3
            
            switch section {
            case .activeChallenges:
                badgeProgressBar.isHidden = false
                badgeDetailLabel.text = "0 / \(badge.goalValue) XP"
                badgeProgressBar.setProgress(0, animated: false)

            case .recentWins:
                badgeProgressBar.isHidden = true
                badgeDetailLabel.text = "Not Earned"

            case .allMilestones:
                badgeProgressBar.isHidden = true
                badgeDetailLabel.text = "Locked"
                
            default:
                badgeProgressBar.isHidden = true
            }
        }
    }
