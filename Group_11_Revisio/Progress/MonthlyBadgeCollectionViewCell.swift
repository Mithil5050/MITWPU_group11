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
            levelLabel.font = .systemFont(ofSize: 22, weight: .semibold)
            levelLabel.textColor = .white
            
            xpValueLabel.font = .systemFont(ofSize: 14, weight: .regular)
            xpValueLabel.textColor = .systemGray
            
            xpProgressBar.layer.cornerRadius = 4
            xpProgressBar.clipsToBounds = true
            xpProgressBar.progressTintColor = .systemBlue
            xpProgressBar.trackTintColor = UIColor.systemBlue.withAlphaComponent(0.2)
        
            if let progressSubView = xpProgressBar.subviews.last {
                progressSubView.layer.cornerRadius = 4
                progressSubView.clipsToBounds = true
            }
        }

        // ✅ Your restored configure method!
        func configure(with badge: Badging.Badge) {
            let manager = ProgressDataManager.shared
            let goalXP = manager.pointsPerLevel
            let displayXP = manager.currentLevelXP
            let currentLevel = manager.userLevel
            
            levelLabel.text = "Level \(currentLevel)"
            xpValueLabel.text = "\(displayXP) / \(goalXP) XP"

            if let image = UIImage(named: "awards_monthly_main") {
                monthlyBadgeImageView.image = image
                monthlyBadgeImageView.alpha = 1.0
                monthlyBadgeImageView.isHidden = false
            } else {
                monthlyBadgeImageView.image = UIImage(systemName: "lock.fill")
                monthlyBadgeImageView.tintColor = .systemGray
                monthlyBadgeImageView.alpha = 0.3
            }
            
            self.contentView.bringSubviewToFront(monthlyBadgeImageView)

            let progress = Float(displayXP) / Float(goalXP)
            
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
            
            let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = self.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurView.layer.cornerRadius = 16
            blurView.clipsToBounds = true
            
            self.contentView.insertSubview(blurView, at: 0)
        }
    }
