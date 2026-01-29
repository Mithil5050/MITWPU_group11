//
//  DailyChallengeCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 27/01/26.
//


import UIKit

class DailyChallengeCell: UICollectionViewCell {
    
    @IBOutlet weak var bgView: UIView! // Add a gradient later if you wish
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Card Styling
        bgView.layer.cornerRadius = 20
        bgView.clipsToBounds = true
        
        // Button Styling
        actionButton.layer.cornerRadius = 14
        actionButton.backgroundColor = .white
        actionButton.setTitleColor(.black, for: .normal)
    }
    
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        // Set your mascot image here if needed, or in XIB
        // imageView.image = UIImage(named: "robot_wave")
    }
}