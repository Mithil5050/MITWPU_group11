//
//  DocumentCell.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 12/12/25.
//

import UIKit

class DocumentCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel?

    func configure(title: String) {
        if let lbl = titleLabel { lbl.text = title } else {
            for v in contentView.subviews { v.removeFromSuperview() }
            let lbl = UILabel(frame: contentView.bounds.insetBy(dx: 4, dy: 4))
            lbl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            lbl.numberOfLines = 2
            lbl.font = UIFont.systemFont(ofSize: 12)
            lbl.textAlignment = .center
            lbl.text = title
            contentView.addSubview(lbl)
        }
    }
}
