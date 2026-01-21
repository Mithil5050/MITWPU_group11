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
    
    enum DayStatus {
        case streak
        case missed
        case current
        case future
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 28
        containerView.clipsToBounds = true
        
        dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        dayLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        dayLabel.textColor = .white
    }
    
    func configure(day: String, status: DayStatus, isSelected: Bool) {
        dayLabel.text = day
        
        var symbolName = ""
        var symbolColor: UIColor = .white
        var symbolScale: CGFloat = 0.9
        
        switch status {
        case .streak:
            symbolName = "flame"
            symbolColor = isSelected ? .white : .white
        case .current:
            symbolName = "circle.fill"
            symbolColor = isSelected ? .white : .white
            symbolScale = 0.3
        case .missed, .future:
            symbolName = "minus"
            symbolColor = isSelected ? .white : .white
        }
        
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .black)
        
        if var image = UIImage(systemName: symbolName, withConfiguration: config) {
            
            if symbolScale != 1.0 {
                let newSize = CGSize(width: image.size.width * symbolScale, height: image.size.height * symbolScale)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                image = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()
            }
            
            let tintedImage = image.withTintColor(symbolColor, renderingMode: .alwaysOriginal)
            
            let attachment = NSTextAttachment()
            attachment.image = tintedImage
            
            let yOffset = (dateLabel.font.capHeight - tintedImage.size.height) / 2
            attachment.bounds = CGRect(x: 0, y: yOffset, width: tintedImage.size.width, height: tintedImage.size.height)
            
            dateLabel.attributedText = NSAttributedString(attachment: attachment)
        }
        
        if isSelected {
            containerView.backgroundColor = UIColor.systemBlue
            dayLabel.textColor = .white
            containerView.layer.borderWidth = 0
        } else {
            containerView.backgroundColor = UIColor(hex: "91C1EF").withAlphaComponent(1.0)
            dayLabel.textColor = .white
        }
    }
}
