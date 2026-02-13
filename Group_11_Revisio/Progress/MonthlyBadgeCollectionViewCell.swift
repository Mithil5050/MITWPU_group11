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
    @IBOutlet weak var mainTitleLabel: UILabel!

    @IBOutlet weak var xpProgressBar: UIProgressView!
    
    @IBOutlet weak var xpValueLabel: UILabel!
    
    @IBOutlet weak var showAllContainerView: UIView!

        // MARK: - Properties
        weak var delegate: MonthlyBadgeCellDelegate?
        
        override func awakeFromNib() {
            super.awakeFromNib()
            setupUI()
            setupCardStyle()
            setupTapGesture()
        }
        
        private func setupUI() {
            // Aesthetic Configuration
            mainTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            mainTitleLabel.textColor = .white
            
            // Style the XP Bar to look like a "Conqueror" level bar
            xpProgressBar.progressTintColor = .systemBlue
            xpProgressBar.trackTintColor = .systemGray5
            xpProgressBar.layer.cornerRadius = 4
            xpProgressBar.clipsToBounds = true
            
            // This label now handles both the Challenge Name and the Points
            xpValueLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            xpValueLabel.textColor = .systemBlue
        }

        /// Updated configure method using only the Title, Progress Bar, and Value Label
        func configure(with badge: Badge) {
            let dataStore = ProgressDataManager.shared
            let currentXP = dataStore.totalXP
            let nextLevelXP = currentXP + dataStore.xpToNextLevel
            
            // 1. Set the Call to Action
            mainTitleLabel.text = "Go For It!"
            
            // 2. Combine Badge Title and XP Fraction into the bottom label
            // Example: "January Challenge • 150 / 500 XP"
            xpValueLabel.text = "\(badge.title) • \(currentXP)/\(nextLevelXP) XP"
            
            // 3. Update the Badge Image
            monthlyBadgeImageView.image = UIImage(named: badge.imageAssetName)
            
            // 4. Update the visual Progress Bar
            let progress = Float(currentXP) / Float(nextLevelXP)
            xpProgressBar.setProgress(progress, animated: true)
        }
        
        // MARK: - Interactions
        private func setupTapGesture() {
            self.contentView.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
            self.contentView.addGestureRecognizer(tapGesture)
        }
        
        @objc private func cardTapped() {
            delegate?.didTapMonthlyBadgeCard()
        }

        // MARK: - Styling
        private func setupCardStyle() {
            // Using a dark, modern aesthetic
            self.contentView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            self.contentView.layer.cornerRadius = 16
            self.contentView.layer.masksToBounds = true
            
            // Elevation shadow
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.3
            self.layer.shadowOffset = CGSize(width: 0, height: 4)
            self.layer.shadowRadius = 6
            self.layer.masksToBounds = false
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 16).cgPath
        }
    }
