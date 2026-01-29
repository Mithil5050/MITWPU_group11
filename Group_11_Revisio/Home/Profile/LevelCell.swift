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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bgView.layer.cornerRadius = 16
        bgView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
    }
    
    func configure(level: Int, currentXP: Int, maxXP: Int) {
        levelLabel.text = "Level \(level)"
        xpLabel.text = "\(currentXP)/\(maxXP) XP"
        progressBar.progress = Float(currentXP) / Float(maxXP)
    }
}