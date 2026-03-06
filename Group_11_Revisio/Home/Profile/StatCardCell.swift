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
           // Let taps pass through bgView to the cell's selection handler
           bgView.isUserInteractionEnabled = false
       }

       func configure(title: String, value: String, icon: String, color: UIColor) {
           titleLabel.text    = title
           valueLabel.text    = value
           iconView.image     = UIImage(systemName: icon)
           iconView.tintColor = color

           // Subtle tinted background per card type
           bgView.backgroundColor = color.withAlphaComponent(0.07)
               .mixed(with: UIColor(white: 0.11, alpha: 1.0), ratio: 0.35)
       }
   }

   // MARK: - UIColor blend helper
   private extension UIColor {
       /// Blends self with `color` at the given `ratio` (0 = all self, 1 = all color).
       func mixed(with color: UIColor, ratio: CGFloat) -> UIColor {
           var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
           var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
           getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
           color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
           let t = max(0, min(1, ratio))
           return UIColor(red:   r1 + (r2 - r1) * t,
                          green: g1 + (g2 - g1) * t,
                          blue:  b1 + (b2 - b1) * t,
                          alpha: a1 + (a2 - a1) * t)
       }
   }

