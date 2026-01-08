//
//  TaskCell.swift
//  Group_11_Revisio
//
//  Created by Your Name on 11/12/25.
//

import UIKit

class TaskCell: UITableViewCell {
    
    @IBOutlet weak var checkmarkView: UIView! // The circular checkmark/radio button
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 🍏 iOS 26 Aesthetic: Rounded container and interactive elements
        containerView.layer.cornerRadius = 12
        containerView.backgroundColor = .systemGray6 // Light background for list item
        
        // Configure the checkmark view (the empty circle)
        checkmarkView.layer.cornerRadius = checkmarkView.frame.height / 2
        checkmarkView.layer.borderColor = UIColor.systemGray3.cgColor
        checkmarkView.layer.borderWidth = 2.0
        
        // Remove selection style
        selectionStyle = .none
    }
    
    // Example function to update the checked state
    func setIsComplete(_ isComplete: Bool) {
        if isComplete {
            checkmarkView.backgroundColor = .systemBlue
            checkmarkView.layer.borderWidth = 0
            // Add a checkmark icon to the view
        } else {
            checkmarkView.backgroundColor = .clear
            checkmarkView.layer.borderWidth = 2.0
        }
    }
}
