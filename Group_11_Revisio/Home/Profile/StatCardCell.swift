//
//  StatCardCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/01/26.
//


import UIKit
class StatCardCell: UICollectionViewCell {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!

    override func awakeFromNib() {
             super.awakeFromNib()
             bgView.layer.cornerRadius = 16
             bgView.backgroundColor = UIColor(white: 0.11, alpha: 1.0)
             bgView.isUserInteractionEnabled = false
         }

         func configure(title: String, value: String, icon: String, color: UIColor) {
             titleLabel.text    = title
             valueLabel.text    = value
             iconView.image     = UIImage(systemName: icon)
             iconView.tintColor = color
             bgView.backgroundColor = UIColor(white: 0.11, alpha: 1.0)
         }
     }

