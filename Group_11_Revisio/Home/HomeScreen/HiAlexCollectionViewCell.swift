//
//  HiAlexCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/11/25.
//

import UIKit

class HiAlexCollectionViewCell: UICollectionViewCell {

    @IBOutlet var BgView: GradientView!
    @IBOutlet weak var hiAlex: UIView!
    
    // 🆕 Create an outlet for the image view if you haven't already.
    // In your XIB, the image view ID is "k4o-IY-NIR".
    // Connect this IBOutlet to that Image View in Interface Builder.
    @IBOutlet weak var robotImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Style Setup
        hiAlex.layer.cornerRadius = 12
        BgView.layer.cornerRadius = 12
        BgView.backgroundColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1)
        
        // 🚀 Load the GIF
        // Make sure the file "robot_wave.gif" is in your project navigator (not Assets.xcassets)
        if let gifImage = UIImage.gifImageWithName("robot_wave") {
            robotImageView.image = gifImage
        } else {
            print("⚠️ Could not load robot_wave.gif")
        }
    }
}
