//
//  ContinueLearningCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/11/25.
//

import UIKit

class ContinueLearningCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var ContinueLearning: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        ContinueLearning.layer.cornerRadius = 12
        ContinueLearning.backgroundColor = UIColor(hex: "F5F5F5")

    }

}
