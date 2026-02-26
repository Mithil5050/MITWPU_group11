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
            setupUI()
            setupCardStyle()
        }
        
    
    private func setupUI() {
        
        allBadgeTitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        allBadgeTitleLabel.textColor = .label
        allBadgeTitleLabel.textAlignment = .center
        
        allBadgeDetailLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        allBadgeDetailLabel.textColor = .secondaryLabel
        allBadgeDetailLabel.textAlignment = .center

    }
    func configure(with badge: Badge) {
        // Title and image from available Badge properties
        allBadgeTitleLabel.text = badge.title
        allBadgeImageView.image = UIImage(named: badge.imageAssetName)

        // Detail may not exist on Badge; clear or hide to avoid stale content
        allBadgeDetailLabel.text = nil

        // Since `isLocked` is not a member of Badge, apply default styling
        allBadgeImageView.alpha = 1.0
        allBadgeDetailLabel.textColor = .secondaryLabel
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
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 12).cgPath
    }
}
