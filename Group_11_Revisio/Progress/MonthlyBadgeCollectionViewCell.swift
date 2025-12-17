//
//  MonthlyBadgeCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import UIKit

// This protocol defines the methods the parent View Controller must implement.
protocol MonthlyBadgeCellDelegate: AnyObject {
    func didTapShowAllButton()
    func didTapMonthlyBadgeCard() // Used for tapping the badge image/card area
}
class MonthlyBadgeCollectionViewCell: UICollectionViewCell {

    
    @IBOutlet weak var monthlyBadgeImageView: UIImageView!
    
    @IBOutlet weak var mainTitleLabel: UILabel!
    
    @IBOutlet weak var challengeNameLabel: UILabel!
    
    @IBOutlet weak var upcomingBadgeLabel: UILabel!
    
    @IBOutlet weak var allBadgesImageView: UIImageView!
    
    @IBOutlet weak var showAllButton: UIButton!
    
    @IBOutlet weak var showAllContainerView: UIView!
    
    // The delegate property allows the cell to notify the AwardsViewController
        weak var delegate: MonthlyBadgeCellDelegate?
        
        override func awakeFromNib() {
            super.awakeFromNib()
            setupCardStyle()
            setupShowAllStyle()
            setupTapGesture()
        }
        
        func configure(with badge: Badge) {
            mainTitleLabel.text = "Go For It"
            challengeNameLabel.text = badge.title
            upcomingBadgeLabel.text = badge.detail
            monthlyBadgeImageView.image = UIImage(named: badge.imageAssetName)
        }
        
        private func setupTapGesture() {
            monthlyBadgeImageView.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(badgeImageTapped))
            monthlyBadgeImageView.addGestureRecognizer(tapGesture)
        }
        
        @objc private func badgeImageTapped() {
            // Notifies the ViewController
            delegate?.didTapMonthlyBadgeCard()
        }

        @IBAction func showAllTapped(_ sender: UIButton) {
            delegate?.didTapShowAllButton()
        }
        
        private func setupCardStyle() {
            self.contentView.backgroundColor = .systemBackground
            self.contentView.layer.cornerRadius = 12
            self.contentView.layer.masksToBounds = true
            
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.1
            self.layer.shadowOffset = CGSize(width: 0, height: 1)
            self.layer.shadowRadius = 3
            self.layer.masksToBounds = false
        }
        
        private func setupShowAllStyle() {
            showAllContainerView.layer.cornerRadius = 8
            showAllContainerView.layer.masksToBounds = true
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 12).cgPath
        }
    }
