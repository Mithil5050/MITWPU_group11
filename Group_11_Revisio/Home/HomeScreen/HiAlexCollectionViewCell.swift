//
//  HiAlexCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/11/25.
//

import UIKit

// 1. Define Protocol
protocol HiAlexCellDelegate: AnyObject {
    func didTapPlayNow()
}

class HiAlexCollectionViewCell: UICollectionViewCell {

    @IBOutlet var BgView: GradientView!
    @IBOutlet weak var hiAlex: UIView!
    @IBOutlet var PlayNow: UIButton!
    @IBOutlet weak var robotImageView: UIImageView!
    
    // 2. Add Delegate Variable
    weak var delegate: HiAlexCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Style Setup
        hiAlex.layer.cornerRadius = 12
        BgView.layer.cornerRadius = 12
        BgView.backgroundColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1)
        PlayNow.layer.cornerRadius = 15
        
        // Load GIF
        if let gifImage = UIImage.gifImageWithName("robot_wave") {
            robotImageView.image = gifImage
        } else {
            print("⚠️ Could not load robot_wave.gif")
        }
        
        // 3. Add Target for Button Press
        PlayNow.addTarget(self, action: #selector(playNowTapped), for: .touchUpInside)
    }
    
    // 4. Handle Action
    @objc func playNowTapped() {
        // Tell the controller to perform the segue
        delegate?.didTapPlayNow()
    }
}
