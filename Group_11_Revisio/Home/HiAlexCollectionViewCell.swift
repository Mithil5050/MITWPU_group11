//
//  HiAlexCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/11/25.
//

import UIKit

class HiAlexCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var hiAlex: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        hiAlex.layer.cornerRadius = 12

    }

}
