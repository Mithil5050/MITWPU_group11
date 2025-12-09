//
//  StudyPlanCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/11/25.
//

import UIKit

class StudyPlanCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var StudyPlan: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        StudyPlan.layer.cornerRadius = 12.0
        StudyPlan.backgroundColor = UIColor(hex: "F5F5F5")
    }

}
