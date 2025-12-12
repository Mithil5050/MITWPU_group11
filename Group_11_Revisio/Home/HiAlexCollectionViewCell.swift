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
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        hiAlex.layer.cornerRadius = 12
        BgView.layer.cornerRadius = 12
        BgView.backgroundColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1)

    }

}
