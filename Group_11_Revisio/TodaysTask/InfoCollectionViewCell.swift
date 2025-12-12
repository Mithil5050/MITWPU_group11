//
//  InfoCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 12/12/25.
//

import UIKit

class InfoCollectionViewCell: UICollectionViewCell {

    @IBOutlet var InfoView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        InfoView.layer.cornerRadius = 12
        InfoView.backgroundColor = UIColor(hex: "F5F5F5")
    }

}
