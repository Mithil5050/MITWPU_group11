//
//  MemberCell.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 12/12/25.
//

import UIKit

class MemberCell: UICollectionViewCell {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Make avatar circular
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
        avatarImageView.clipsToBounds = true
    }
    
    func configure(name: String) {
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    }
}
