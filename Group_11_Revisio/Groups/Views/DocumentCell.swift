//
//  DocumentCell.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 12/12/25.
//

import UIKit

class DocumentCell: UICollectionViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = UIColor.secondarySystemBackground
        contentView.layer.cornerRadius = 14
        contentView.clipsToBounds = true

        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
    }

    func configure(filename: String) {
        nameLabel.text = filename

        let ext = (filename as NSString).pathExtension.lowercased()

        switch ext {
        case "pdf":
            iconImageView.image = UIImage(systemName: "doc.richtext.fill")
        case "doc", "docx":
            iconImageView.image = UIImage(systemName: "doc.text.fill")
        default:
            iconImageView.image = UIImage(systemName: "doc.fill")
        }
    }
}
