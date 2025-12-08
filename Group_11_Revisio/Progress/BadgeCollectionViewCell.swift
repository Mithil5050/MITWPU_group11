//
//  BadgeCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 08/12/25.
//

import UIKit

class BadgeCollectionViewCell: UICollectionViewCell {
    
    // The image for the badge (medal or lock icon)
    
    @IBOutlet weak var badgeImageView: UIImageView!
    
    // The main title (e.g., "Squad MVP")
    
    @IBOutlet weak var titleLabel: UILabel!
    
    // The detail line (e.g., "Earned: 13/09/2025" or "Unlock the badge")
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
            super.awakeFromNib()
            // Ensure the card styling (rounded corners, shadows) is applied
            setupCardStyle()
        }
        
        // MARK: - Configuration Method
        
        // Called by AwardsViewController to fill the cell with data
        func configure(with badge: Badge) {
            
            titleLabel.text = badge.title
            detailLabel.text = badge.detail
            
            // Load the image from your Assets Catalog
            badgeImageView.image = UIImage(named: badge.imageAssetName)
            
            // Apply visual states based on lock status
            if badge.isLocked {
                // Apply grayscale or dimming effect
                badgeImageView.alpha = 0.5
                detailLabel.textColor = .secondaryLabel
            } else {
                badgeImageView.alpha = 1.0
                detailLabel.textColor = .systemGray
            }
        }

        // You would typically define this method to handle rounded corners and shadows
        private func setupCardStyle() {
            self.contentView.backgroundColor = .secondarySystemBackground
            self.contentView.layer.cornerRadius = 12
            self.contentView.layer.masksToBounds = true
            // Shadow setup (optional)
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.1
            self.layer.shadowOffset = CGSize(width: 0, height: 1)
            self.layer.shadowRadius = 3
            self.layer.masksToBounds = false
        }
    }

