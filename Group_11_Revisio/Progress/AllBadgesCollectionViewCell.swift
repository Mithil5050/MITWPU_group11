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
            setupCardStyle()
        }
        
        // Configured specifically for Title and Earned Date
        func configure(with badge: Badge) {
            allBadgeTitleLabel.text = badge.title
            allBadgeImageView.image = UIImage(named: badge.imageAssetName)
            
            // Setting the subtitle to the badge's detail (the date)
            allBadgeDetailLabel.text = badge.detail
            
            if badge.isLocked {
                allBadgeImageView.alpha = 0.5
                allBadgeDetailLabel.textColor = .secondaryLabel
            } else {
                allBadgeImageView.alpha = 1.0
                allBadgeDetailLabel.textColor = .systemGray
            }
        }
        
        private func setupCardStyle() {
            allBadgeCardView.backgroundColor = .systemGray6
            allBadgeCardView.layer.cornerRadius = 12
            allBadgeCardView.layer.masksToBounds = true
            
            // Shadow configuration to match your original design
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.1
            self.layer.shadowOffset = CGSize(width: 0, height: 1)
            self.layer.shadowRadius = 3
            self.layer.masksToBounds = false
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // Path must match the 12.0 corner radius
            self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 12).cgPath
        }
    }
