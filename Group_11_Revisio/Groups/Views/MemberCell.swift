//
//  MemberCell.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 12/12/25.
//

import UIKit

class MemberCell: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(name: String) {
        if let lbl = nameLabel { lbl.text = name }
        else {
            for v in contentView.subviews { v.removeFromSuperview() }
            let lbl = UILabel(frame: contentView.bounds)
            lbl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            lbl.textAlignment = .center
            lbl.font = UIFont.systemFont(ofSize: 12)
            lbl.text = name
            contentView.addSubview(lbl)
        }
    }
}
