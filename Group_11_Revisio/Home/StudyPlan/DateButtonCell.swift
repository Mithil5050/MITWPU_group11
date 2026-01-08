//
// DateButtonCell.swift
// Group_11_Revisio
//
// Created by Mithil on 10/12/25.
//

import UIKit

// Renamed from CalendarSPCollectionViewCell to reflect purpose
class DateButtonCell: UICollectionViewCell {
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 🍏 iOS Aesthetic: Rounded capsule look
        // Assumes a cell height of 56 points for a perfect capsule shape (28 * 2)
        containerView.layer.cornerRadius = 28
        containerView.clipsToBounds = true
        
        // Initial setup for the unselected color is now managed in configure()
        // The conflicting dynamic color block has been removed.
    }
    
    // Function to visually select/unselect the cell
    func configure(day: String, dateNumber: String, isSelected: Bool) {
        dayLabel.text = day
        dateLabel.text = dateNumber

        if isSelected {
            // Selected state: iOS standard accent color with white text
            containerView.backgroundColor = UIColor(hex: "91C1EF")
            dayLabel.textColor = .systemBlue
            dateLabel.textColor = .systemBlue
        } else {
            // Unselected state: Uses the requested static hex color
            // This color will not change in Dark Mode.
            containerView.backgroundColor = UIColor(hex: "91C1EF")
            
            // Text colors set to adapt to system dark/light mode
            dayLabel.textColor = .white
            dateLabel.textColor = .white
        }
    }
}
