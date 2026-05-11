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

    // MARK: - Setup

    private func setupUI() {
        badgeCardView.layer.cornerRadius = 12
        // clipsToBounds must be false so the shadow renders outside the card bounds
        badgeCardView.clipsToBounds      = false

        // Shadow — visible in light mode, subtle in dark mode
        badgeCardView.layer.shadowColor   = UIColor.black.cgColor
        badgeCardView.layer.shadowOpacity = 0.10
        badgeCardView.layer.shadowRadius  = 6
        badgeCardView.layer.shadowOffset  = CGSize(width: 0, height: 3)

        // Clip inner content to rounded corners via a sublayer mask
        badgeCardView.layer.cornerCurve = .continuous

        badgeTitleLabel.numberOfLines  = 0
        badgeDetailLabel.numberOfLines = 0
        
        // Remove progress bar entirely and use default 4pt stack spacing
        badgeProgressBar.removeFromSuperview()
        
        // Shrink the badge icon to 60x60
        badgeImageView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                constraint.constant = 60
            }
        }
    }

    // MARK: - Empty State

    func showEmptyState(section: AwardsSection) {
        badgeCardView.isHidden        = false
        badgeCardView.backgroundColor = .clear

        badgeImageView.isHidden   = true

        if section == .activeChallenges {
            badgeTitleLabel.text  = "Ongoing Challenges will appear here"
            badgeDetailLabel.text = "Start learning to gain Badges and XP."
        } else if section == .recentWins {
            badgeTitleLabel.text  = "Achievements will appear here"
            badgeDetailLabel.text = "Earn badges as you progress through your learning journey."
        }
    

        badgeTitleLabel.isHidden      = false
        badgeTitleLabel.textColor     = .label           // adaptive: dark in light mode, light in dark mode
        badgeTitleLabel.font          = .systemFont(ofSize: 14, weight: .bold)
        badgeTitleLabel.textAlignment = .center

        badgeDetailLabel.isHidden      = false
        badgeDetailLabel.textColor     = .secondaryLabel  // adaptive grey
        badgeDetailLabel.font          = .systemFont(ofSize: 12, weight: .regular)
        badgeDetailLabel.textAlignment = .center

        if let stackView = badgeTitleLabel.superview as? UIStackView {
            stackView.alignment    = .center
            stackView.axis         = .vertical
            stackView.distribution = .fill
            stackView.spacing      = 4
        }
    }

    // MARK: - Configure

    func configure(with badge: Badging.Badge, forSection section: AwardsSection) {
        badgeCardView.isHidden = false

        // Adaptive card background: subtle tint in both light and dark mode
        badgeCardView.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.08)   // faint white overlay in dark
                : UIColor(white: 0.0, alpha: 0.04)   // faint dark overlay in light
        }

        badgeImageView.isHidden   = false
        badgeTitleLabel.isHidden  = false
        badgeDetailLabel.isHidden = false

        badgeTitleLabel.text      = badge.title
        badgeTitleLabel.font      = .systemFont(ofSize: 14, weight: .bold)
        badgeTitleLabel.textColor = .label           // adaptive
        badgeTitleLabel.textAlignment = section == .allMilestones ? .center : .left

        badgeDetailLabel.textColor = .secondaryLabel  // adaptive
        badgeDetailLabel.font      = .systemFont(ofSize: 12, weight: .regular)

        if let imageName = Badging.imageName(for: badge) {
            badgeImageView.image = UIImage(named: imageName)
            badgeImageView.alpha = badge.isEarned ? 1.0 : 0.3
        } else {
            badgeImageView.image     = UIImage(systemName: "lock.fill")
            badgeImageView.tintColor = .systemGray
        }

        if badge.isEarned {
            badgeDetailLabel.text = "Earned!"
        } else {
            badgeDetailLabel.text = "\(badge.currentValue) / \(badge.goalValue) \(badge.category.unitLabel)"
        }
    }
}
