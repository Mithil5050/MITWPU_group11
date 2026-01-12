//
//  InfoCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 12/12/25.
//

import UIKit

class InfoCollectionViewCell: UICollectionViewCell {
    @IBOutlet var Flame: UIImageView!
    
    @IBOutlet var InfoView: UIView!
    override func awakeFromNib() {
            super.awakeFromNib()
            
            // Corner Radius setup
            InfoView.layer.cornerRadius = 15
            Flame.layer.cornerRadius = 12
            
            // Dynamic Background Color
            // Light Mode: #FFF1DC (Cream), Dark Mode: System Secondary Grouped (Dark Gray)
            InfoView.backgroundColor = UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return .secondarySystemGroupedBackground
                } else {
                    return UIColor(hex: "FFF1DC")
                }
            }
        }

}
