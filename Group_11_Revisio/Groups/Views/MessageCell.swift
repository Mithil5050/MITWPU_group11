//
//  MessageCell.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 10/12/25.
//

import UIKit

class MessageCell: UITableViewCell {

    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!

    // leading/trailing constraints wired from storyboard for bubble alignment
    @IBOutlet weak var bubbleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleTrailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        messageLabel.numberOfLines = 0
        bubbleView.layer.cornerRadius = 16
        bubbleView.clipsToBounds = true
        bubbleView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        messageLabel.textColor = .black
    }

    func configure(with message: Message) {
        messageLabel.text = message.content
        // Incoming style only — outgoing messages use a different cell type
        bubbleLeadingConstraint.isActive = true
        bubbleTrailingConstraint.isActive = false
        bubbleView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        messageLabel.textColor = .black
    }
}
