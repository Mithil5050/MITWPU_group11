//
//  DateButtonCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 10/12/25.
//

import UIKit

// Renamed from CalendarSPCollectionViewCell to reflect purpose
class DateButtonCell2: UICollectionViewCell {
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel! // Example: "Fri" and the date number
    @IBOutlet weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 🍏 iOS 26 Aesthetic: Rounded capsule look
        containerView.layer.cornerRadius = 28 // Half of 60pt cell height for capsule shape
        containerView.clipsToBounds = true
        
        // 🍏 iOS 26 Aesthetic: Ultra Thin Material/Liquid Glass effect (simulated)
        // In a real app, this would involve setting a custom background effect view.
        containerView.backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 0.8) : UIColor(white: 0.95, alpha: 0.8)
        }
    }
    
    // Function to visually select the cell (e.g., 'Tue' in the screenshot)
    func configure(day: String, dateNumber: String, isSelected: Bool) {
        dayLabel.text = day
        dateLabel.text = dateNumber // <-- Use the date number here

        if isSelected {
            containerView.backgroundColor = .systemBlue
            dayLabel.textColor = .white
            dateLabel.textColor = .white
        } else {
            // Set unselected appearance
            containerView.backgroundColor = .systemGray5
            dayLabel.textColor = .label
            dateLabel.textColor = .label
        }
    }
}
