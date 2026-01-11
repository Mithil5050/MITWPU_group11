//
//  DateButtonCell.swift
//  Group_11_Revisio
//
//  Updated for SF Symbols (Flame)
//

import UIKit

class DateButtonCell: UICollectionViewCell {
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    // Define the possible states for a day
    enum DayStatus {
        case streak   // Flame SF Symbol
        case missed   // -
        case current  // •
        case future   // -
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 🍏 iOS 26 Aesthetic: Capsule Shape
        containerView.layer.cornerRadius = 28
        containerView.clipsToBounds = true
        
        // Font adjustments
        dateLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        dayLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    }
    
    func configure(day: String, status: DayStatus, isSelected: Bool) {
        dayLabel.text = day
        
        // 1. Determine which SF Symbol to use
        var symbolName = ""
        var symbolColor: UIColor = .label
        var symbolScale: CGFloat = 0.9 // Scale factor for the dot
        
        switch status {
        case .streak:
            symbolName = "flame.fill"
            symbolColor = isSelected ? .white : .systemOrange
        case .current:
            symbolName = "circle.fill" // Use circle.fill as the dot
            symbolColor = isSelected ? .white : .label
            symbolScale = 0.3 // Make it smaller to look like a dot
        case .missed, .future:
            symbolName = "minus"
            symbolColor = isSelected ? .white : .secondaryLabel
        }
        
        // 2. Create the Configuration
        // using a heavy weight ensures the minus and dot are clearly visible
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .black)
        
        if var image = UIImage(systemName: symbolName, withConfiguration: config) {
            
            // Apply scaling if it's the dot (so it's not a giant circle)
            if symbolScale != 1.0 {
                let newSize = CGSize(width: image.size.width * symbolScale, height: image.size.height * symbolScale)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                image = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()
            }
            
            // Tint the image manually
            let tintedImage = image.withTintColor(symbolColor, renderingMode: .alwaysOriginal)
            
            // Create attachment
            let attachment = NSTextAttachment()
            attachment.image = tintedImage
            
            // Fix vertical alignment (SF Symbols inside text can sometimes sit too high)
            // A slight negative bound shifts it down to center it
            let yOffset = (dateLabel.font.capHeight - tintedImage.size.height) / 2
            attachment.bounds = CGRect(x: 0, y: yOffset, width: tintedImage.size.width, height: tintedImage.size.height)
            
            dateLabel.attributedText = NSAttributedString(attachment: attachment)
        }
        
        // 3. Handle Container Colors
        if isSelected {
            containerView.backgroundColor = UIColor.systemBlue
            dayLabel.textColor = .white
            containerView.layer.borderWidth = 0
        } else {
            containerView.backgroundColor = UIColor(hex: "91C1EF").withAlphaComponent(0.4)
            dayLabel.textColor = .label
        }
    }
}
