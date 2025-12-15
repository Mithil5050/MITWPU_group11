//
//  CalendarDayCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 15/12/25.
//

import UIKit

// NOTE: DayData struct is defined in StreaksCalendarViewController.swift,
// so it is accessible here.

class CalendarDayCollectionViewCell: UICollectionViewCell {
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        return label
    }()
    
    // MARK: - Initialization and Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        contentView.addSubview(dayLabel)
        
        NSLayoutConstraint.activate([
            // Simple constraints for perfect centering
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        
        contentView.layer.masksToBounds = true
    }
    
    // MARK: - Layout for Circular Shape
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Makes the contentView perfectly circular
        contentView.layer.cornerRadius = contentView.bounds.width / 2
    }
    
    // MARK: - Configuration
    
    func configure(with day: DayData) {
        
        if day.date == 0 {
            dayLabel.text = ""
            contentView.backgroundColor = .clear
            contentView.layer.borderWidth = 0
            return
        }
        
        dayLabel.text = String(day.date)
        
        if day.isStreaked {
            contentView.backgroundColor = .systemOrange
            dayLabel.textColor = .white
            contentView.layer.borderWidth = 0
            
        } else if day.isCurrentMonth {
            contentView.backgroundColor = .clear
            contentView.layer.borderColor = UIColor.systemGray4.cgColor
            contentView.layer.borderWidth = 1
            dayLabel.textColor = .label
            
        } else {
            contentView.backgroundColor = .clear
            contentView.layer.borderWidth = 0
            dayLabel.textColor = .tertiaryLabel
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dayLabel.text = nil
        dayLabel.textColor = .label
        contentView.backgroundColor = .clear
        contentView.layer.borderColor = UIColor.clear.cgColor
        contentView.layer.borderWidth = 0
    }
}
