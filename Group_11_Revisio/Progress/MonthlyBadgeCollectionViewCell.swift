//
//  MonthlyBadgeCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import UIKit


protocol MonthlyBadgeCellDelegate: AnyObject {
    func didTapShowAllButton()
    func didTapMonthlyBadgeCard()
}
class MonthlyBadgeCollectionViewCell: UICollectionViewCell {

    
    @IBOutlet weak var monthlyBadgeImageView: UIImageView!
    @IBOutlet weak var levelLabel: UILabel!

    @IBOutlet weak var xpProgressBar: UIProgressView!
    
    @IBOutlet weak var xpValueLabel: UILabel!
    
    @IBOutlet weak var monthlyBadgeContainerView: UIView!

        weak var delegate: MonthlyBadgeCellDelegate?
                    
        override func awakeFromNib() {
            super.awakeFromNib()
            setupAppleLayout()
            setupCardStyle()
            setupImageTapGesture()
        }
                    
        private func setupAppleLayout() {
            // Typography Hierarchy: Level 2 (big, semibold)
            levelLabel.font = .systemFont(ofSize: 22, weight: .semibold)
            levelLabel.textColor = .white
            
            // XP -> Smaller, secondary color
            xpValueLabel.font = .systemFont(ofSize: 14, weight: .regular)
            xpValueLabel.textColor = .systemGray
            
            // Progress Bar styling
            xpProgressBar.layer.cornerRadius = 4
            xpProgressBar.clipsToBounds = true
            xpProgressBar.progressTintColor = .systemBlue
            xpProgressBar.trackTintColor = UIColor.systemBlue.withAlphaComponent(0.2)
        
            
            // Ensure the inner progress bar also has rounded corners
            if let progressSubView = xpProgressBar.subviews.last {
                progressSubView.layer.cornerRadius = 4
                progressSubView.clipsToBounds = true
            }
        }

        func configure(with badge: Badge) {
            let manager = ProgressDataManager.shared
            
            // Use the pointsPerLevel from your manager (100)
            let goalXP = manager.pointsPerLevel
            
            // Use the modulo logic from manager to reset display to 0 upon level up
            let displayXP = manager.currentLevelXP
            let currentLevel = manager.userLevel
            
            // Update Labels
            levelLabel.text = "Level \(currentLevel)"
            xpValueLabel.text = "\(displayXP) / \(goalXP) XP"

            // Image Handling
            if let image = UIImage(named: "awards_monthly_main") {
                monthlyBadgeImageView.image = image
                monthlyBadgeImageView.alpha = 1.0
                monthlyBadgeImageView.isHidden = false
            } else {
                // Fallback for missing assets
                monthlyBadgeImageView.image = UIImage(systemName: "lock.fill")
                monthlyBadgeImageView.tintColor = .systemGray
                monthlyBadgeImageView.alpha = 0.3
            }
            
            // Ensure image is visible over the background blur
            self.contentView.bringSubviewToFront(monthlyBadgeImageView)

            // 0.3s Ease-In-Out Animation
            let progress = Float(displayXP) / Float(goalXP)
            
            // If displayXP is 0 (new level), reset bar without animation first to avoid weird sliding
            if displayXP == 0 {
                xpProgressBar.setProgress(0, animated: false)
            }
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.xpProgressBar.setProgress(progress, animated: true)
            }
        }
                    
        private func setupImageTapGesture() {
            monthlyBadgeImageView.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
            monthlyBadgeImageView.addGestureRecognizer(tapGesture)
        }
                    
        @objc private func imageTapped() {
            delegate?.didTapMonthlyBadgeCard()
        }

        private func setupCardStyle() {
            self.backgroundColor = .clear
            self.contentView.backgroundColor = .clear
            
            // Subtle background blur
            let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = self.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurView.layer.cornerRadius = 16
            blurView.clipsToBounds = true
            
            // Insert at index 0 to stay behind labels and images
            self.contentView.insertSubview(blurView, at: 0)
        }
    }
