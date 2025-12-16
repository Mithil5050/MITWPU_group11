//
//  MonthlyBadgeCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import UIKit

class MonthlyBadgeCollectionViewCell: UICollectionViewCell {

    
    @IBOutlet weak var monthlyBadgeImageView: UIImageView!
    
    @IBOutlet weak var mainTitleLabel: UILabel!
    
    @IBOutlet weak var challengeNameLabel: UILabel!
    
    @IBOutlet weak var upcomingBadgeLabel: UILabel!
    
    @IBOutlet weak var allBadgesImageView: UIImageView!
    
    @IBOutlet weak var showAllButton: UIButton!
    
    @IBOutlet weak var showAllContainerView: UIView!
    
    // MARK: - Lifecycle & Setup
        
        override func awakeFromNib() {
            super.awakeFromNib()
            // Apply the card styling immediately after loading from XIB
            setupCardStyle()
            // Apply styling to the "Show All" area if it has a separate design
            setupShowAllStyle()
        }
        
        // MARK: - Configuration Method
        
        // Called by AwardsViewController (Index 0) to fill the cell with data
        // Ensure the 'Badge' struct is accessible (e.g., defined in DataModels.swift)
        func configure(with badge: Badge) {
            
            mainTitleLabel.text = badge.title
            challengeNameLabel.text = badge.detail
            
            // Load the image from your Assets Catalog
            monthlyBadgeImageView.image = UIImage(named: badge.imageAssetName)
            
            // You might set the coins images or 'Show All' based on other logic here.
        }
        
        // MARK: - Styling Methods
        
        private func setupCardStyle() {
            let radius: CGFloat = 12
            
            // 1. Apply Corner Radius and Background to the contentView (the card itself)
            // Use a slightly different background if needed, like white or primary system background.
            self.contentView.backgroundColor = .systemBackground
            self.contentView.layer.cornerRadius = radius
            self.contentView.layer.masksToBounds = true
            
            // 2. Apply Shadow to the outer cell layer
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.1 // Light shadow
            self.layer.shadowOffset = CGSize(width: 0, height: 1)
            self.layer.shadowRadius = 3
            self.layer.masksToBounds = false // Crucial for shadow visibility
        }
        
        private func setupShowAllStyle() {
            // If the 'Show All' container needs rounded corners (like the image shows), apply them here.
            let smallRadius: CGFloat = 8
            showAllContainerView.layer.cornerRadius = smallRadius
            showAllContainerView.layer.masksToBounds = true
            // Set a distinct background color for the 'Show All' area, if desired
            // showAllContainerView.backgroundColor = UIColor(named: "CoinContainerColor") ?? .systemGray5
        }

        // MARK: - Layout Update
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // Update the shadow path whenever the cell's size or layout changes
            self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 12).cgPath
        }
    }
