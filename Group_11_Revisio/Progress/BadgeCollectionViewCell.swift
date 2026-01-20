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
            setupCardStyle()
        }
        
        // MARK: - Configuration Method
        
    func configure(with badge: Badge) {
        badgeTitleLabel.text = badge.title
        badgeImageView.image = UIImage(named: badge.imageAssetName)
        
        // Always use the detail label for your "6 out of 10" text
        badgeDetailLabel.text = badge.detail
        badgeDetailLabel.isHidden = false
        
        // Manage the progress bar separately if it exists in this cell
        if let progressBar = badgeProgressBar {
            progressBar.progress = 0.6 // You can still hardcode this or add it to the model later
            progressBar.isHidden = false
        }
    }
        private func setupCardStyle() {
            
            let radius: CGFloat = 12
            
            
           badgeCardView.backgroundColor = .systemGray6
            badgeCardView.layer.cornerRadius = radius
            badgeCardView.layer.masksToBounds = true
            
          
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
           
            self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 12).cgPath
        }
    }
