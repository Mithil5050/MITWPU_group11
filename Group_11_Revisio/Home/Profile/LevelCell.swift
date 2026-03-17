//
//  LevelCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/01/26.
//

import UIKit

// Delegate so the cell can tell ProfileViewController to navigate
protocol LevelCellDelegate: AnyObject {
    func didTapXPCard()
}

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
            
            // 🛑 CRITICAL FIX: Force inner views to ignore touches so the CollectionView gets them!
            bgView.isUserInteractionEnabled = false
            levelBadgeContainer.isUserInteractionEnabled = false

            levelLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            xpLabel.font    = UIFont.systemFont(ofSize: 12, weight: .regular)

            progressBar.layer.cornerRadius = 4
            progressBar.clipsToBounds      = true
            progressBar.progressTintColor  = .systemBlue
            progressBar.trackTintColor     = UIColor.systemBlue.withAlphaComponent(0.2)

            badgeView.frame            = levelBadgeContainer.bounds
            badgeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            levelBadgeContainer.addSubview(badgeView)
            levelBadgeContainer.backgroundColor = .clear
        }

        func configure(level: Int, currentXP: Int, maxXP: Int) {
            levelLabel.text = "Level \(level)"
            badgeView.setLevel(level)
            xpLabel.text    = "\(currentXP)/\(maxXP) XP"

            let progress = maxXP > 0 ? Float(currentXP) / Float(maxXP) : 0
            UIView.animate(withDuration: 0.3) {
                self.progressBar.setProgress(progress, animated: true)
            }
        }
    }
