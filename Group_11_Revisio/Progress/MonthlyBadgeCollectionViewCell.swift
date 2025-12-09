//
//  MonthlyBadgeCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 08/12/25.
//

import UIKit

class MonthlyBadgeCollectionViewCell: UICollectionViewCell {
    
    
    
    @IBOutlet weak var monthlyBadgeImageView: UIImageView!
    
    @IBOutlet weak var mainTitleLabel: UILabel!
    
    @IBOutlet weak var challengeNameLabel: UILabel!
    
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var allBadgesImagesView: UIImageView!
    
    @IBOutlet weak var showAllButton: UIButton!
   
    override func awakeFromNib() {
            super.awakeFromNib()
            setupCardStyle()
        }
        
        // MARK: - Configuration Method
        
        // Called by AwardsViewController to load data
        func configure(with badge: Badge) {
            
            mainTitleLabel.text = "Go For It"
            challengeNameLabel.text = badge.title
            subtitleLabel.text = badge.detail
            
            monthlyBadgeImageView.image = UIImage(named: badge.imageAssetName)
            
            // Ensure "Show All" is visible and formatted
          showAllButton.setTitle("Show All", for: .normal)
            // Optionally, hide the button if the badge is locked
        }

        // Applying the card styling (rounded corners, shadow)
        private func setupCardStyle() {
            self.contentView.backgroundColor = .systemYellow.withAlphaComponent(0.1) // Light card background
            self.contentView.layer.cornerRadius = 12
            self.contentView.layer.masksToBounds = true
            // Shadow setup
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.15
            self.layer.shadowOffset = CGSize(width: 0, height: 2)
            self.layer.shadowRadius = 4
            self.layer.masksToBounds = false
        }
    }

