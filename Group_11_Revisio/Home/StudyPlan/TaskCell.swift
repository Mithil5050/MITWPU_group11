//
//  TaskCell.swift
//  Group_11_Revisio
//
//  Updated for Checkmark Icon
//

import UIKit

class TaskCell: UITableViewCell {
    
    @IBOutlet weak var checkmarkView: UIView! // The circular container
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

    // 🆕 Create the checkmark image view programmatically
    private let checkmarkImageView = UIImageView()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 🍏 iOS Aesthetic: Rounded container and interactive elements
        containerView.layer.cornerRadius = 12
        containerView.backgroundColor = .systemGray6
        
        // Configure the container circle
        checkmarkView.layer.cornerRadius = checkmarkView.frame.height / 2
        checkmarkView.layer.borderColor = UIColor.systemGray3.cgColor
        checkmarkView.layer.borderWidth = 2.0
        
        // 🆕 Setup the checkmark icon inside the view
        setupCheckmarkIcon()
        
        // Remove selection style
        selectionStyle = .none
    }
    
    private func setupCheckmarkIcon() {
        // Use SF Symbol "checkmark"
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        checkmarkImageView.image = UIImage(systemName: "checkmark", withConfiguration: config)
        checkmarkImageView.tintColor = .white // White icon
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        
        checkmarkView.addSubview(checkmarkImageView)
        
        // Center the icon inside the circle
        NSLayoutConstraint.activate([
            checkmarkImageView.centerXAnchor.constraint(equalTo: checkmarkView.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: checkmarkView.centerYAnchor),
            // Make it slightly smaller than the circle (24pt)
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 14),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    // Function to update the checked state
    func setIsComplete(_ isComplete: Bool) {
        if isComplete {
            // ✅ Completed: Blue Fill + White Checkmark
            checkmarkView.backgroundColor = .systemBlue
            checkmarkView.layer.borderWidth = 0
            checkmarkImageView.isHidden = false // Show Icon
        } else {
            // ⭕️ Incomplete: Clear + Gray Border
            checkmarkView.backgroundColor = .clear
            checkmarkView.layer.borderColor = UIColor.systemGray3.cgColor
            checkmarkView.layer.borderWidth = 2.0
            checkmarkImageView.isHidden = true // Hide Icon
        }
    }
}
