//
//  AllBadgesCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 17/01/26.
//

import UIKit

class AllBadgesCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var allBadgeCardView: UIView!
    
    @IBOutlet weak var allBadgeImageView: UIImageView!
    
    @IBOutlet weak var allBadgeTitleLabel: UILabel!
    
    @IBOutlet weak var allBadgeDetailLabel: UILabel!
    
    override func awakeFromNib() {
            super.awakeFromNib()
            setupCardStyle() // Keeping your exact card style
        }
        
        // MARK: - Configuration Method
        func configure(with badge: Badge) {
            allBadgeTitleLabel.text = badge.title
            allBadgeDetailLabel.text = badge.detail
            allBadgeImageView.image = UIImage(named: badge.imageAssetName)
            
            // Apply your exact lock status visual states
            if badge.isLocked {
                allBadgeImageView.alpha = 0.5
                allBadgeDetailLabel.textColor = .secondaryLabel
            } else {
                allBadgeImageView.alpha = 1.0
                allBadgeDetailLabel.textColor = .systemGray
            }
        }
        
        private func setupCardStyle() {
            let radius: CGFloat = 12
            
            // Match your systemGray6 background and corner radius
            allBadgeCardView.backgroundColor = .systemGray6
            allBadgeCardView.layer.cornerRadius = radius
            allBadgeCardView.layer.masksToBounds = true
            
            // Match your specific shadow configuration
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.1
            self.layer.shadowOffset = CGSize(width: 0, height: 1)
            self.layer.shadowRadius = 3
            self.layer.masksToBounds = false
            self.layer.shouldRasterize = true
            self.layer.rasterizationScale = UIScreen.main.scale
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // Ensure shadow path matches the rounded corners exactly
            self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 12).cgPath
        }
    }
