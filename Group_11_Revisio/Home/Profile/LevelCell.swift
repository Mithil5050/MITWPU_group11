//
//  LevelCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/01/26.
//

import UIKit

class LevelCell: UICollectionViewCell {
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var xpLabel: UILabel!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var levelBadgeContainer: UIView!
    private let badgeView = LevelBadgeView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        bgView.layer.cornerRadius = 16
        bgView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        
        levelLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        xpLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        // Progress Bar styling
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        progressBar.progressTintColor = .systemPurple
        progressBar.trackTintColor = UIColor.systemBlue.withAlphaComponent(0.2)
        
        // Setup Badge inside the container
        badgeView.frame = levelBadgeContainer.bounds
        badgeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        levelBadgeContainer.addSubview(badgeView)
        levelBadgeContainer.backgroundColor = .clear
    }
    
    func configure(level: Int, currentXP: Int, maxXP: Int) {
        // Level number inside shield
        levelLabel.text = "Level \(level)"
        badgeView.setLevel(level)
        
        // XP text with reset logic
        xpLabel.text = "\(currentXP)/\(maxXP) XP"
        
        // Smooth animation
        let progressValue = Float(currentXP) / Float(maxXP)
        UIView.animate(withDuration: 0.3) {
            self.progressBar.setProgress(progressValue, animated: true)
        }
    }
}
