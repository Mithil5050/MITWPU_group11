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
            badgeCardView.layer.cornerRadius = 12
            badgeCardView.clipsToBounds = true
            
            badgeTitleLabel.numberOfLines = 0
            badgeDetailLabel.numberOfLines = 0
        }

     
        func showEmptyState(section: AwardsSection) {
          
            badgeCardView.isHidden = false
            badgeCardView.backgroundColor = .clear
            
            badgeProgressBar.isHidden = true
            badgeImageView.isHidden = true
            
            if section == .activeChallenges {
                badgeTitleLabel.text = "Challenged will appear here"
                badgeDetailLabel.text = "Start learning to gain XP."
            } else if section == .recentWins {
                badgeTitleLabel.text = "Achivements will appear here"
                badgeDetailLabel.text = "Your badges will appear here as you learn."
            }
            
          
            badgeTitleLabel.isHidden = false
            badgeTitleLabel.textColor = .white
            badgeTitleLabel.font = .systemFont(ofSize: 14, weight: .bold)
            badgeTitleLabel.textAlignment = .center
            
            badgeDetailLabel.isHidden = false
            badgeDetailLabel.textColor = .systemGray
            badgeDetailLabel.font = .systemFont(ofSize: 12, weight: .medium)
            badgeDetailLabel.textAlignment = .center
            
        // Adjust the StackView
            if let stackView = badgeTitleLabel.superview as? UIStackView {
                stackView.alignment = .center
                stackView.axis = .vertical
                stackView.distribution = .fill
                stackView.spacing = 4
            }
        }

        func configure(with badge: Badging.Badge, forSection section: AwardsSection) {
            
            badgeCardView.isHidden = false
            badgeCardView.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
            badgeImageView.isHidden = false
            badgeTitleLabel.isHidden = false
            badgeDetailLabel.isHidden = false
            
            badgeTitleLabel.text = badge.title
            badgeTitleLabel.font = .systemFont(ofSize: 14, weight: .bold)
            badgeTitleLabel.textAlignment = section == .allMilestones ? .center : .left
            
            if let imageName = Badging.imageName(for: badge) {
                badgeImageView.image = UIImage(named: imageName)
                badgeImageView.alpha = badge.isEarned ? 1.0 : 0.3
            } else {
                badgeImageView.image = UIImage(systemName: "lock.fill")
                badgeImageView.tintColor = .systemGray
            }
            
            if section == .activeChallenges {
                badgeProgressBar.isHidden = false
                badgeProgressBar.setProgress(badge.progress, animated: true)
                badgeDetailLabel.text = "\(badge.currentValue) / \(badge.goalValue)"
            } else {
                badgeProgressBar.isHidden = true
                badgeDetailLabel.text = badge.isEarned ? "Earned!" : "Locked"
            }
        }
    }
