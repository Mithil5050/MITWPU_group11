//
//  DocumentCell.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 11/12/25.
//

import UIKit

class DocumentCell: UICollectionViewCell {
    @IBOutlet weak var iconImageView: UIImageView! // optional if you create xib
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel?.font = UIFont.systemFont(ofSize: 12)
        nameLabel?.textAlignment = .center
    }
}
