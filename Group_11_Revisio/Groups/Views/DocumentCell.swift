//
//  DocumentCell.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 12/12/25.
//

import UIKit

class DocumentCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    func configure(filename: String) {
        titleLabel.text = filename
    }
}
