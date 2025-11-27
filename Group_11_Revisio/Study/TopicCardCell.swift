//
//  TopicCardCell.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import UIKit

class TopicCardCell: UITableViewCell {
    
    
    @IBOutlet var cardContainerView: UIView!
    
    @IBOutlet var iconImageView: UIImageView!
    
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        cardContainerView.backgroundColor = .cardBackgroundColor
        cardContainerView.layer.cornerRadius = 8.0
        cardContainerView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
