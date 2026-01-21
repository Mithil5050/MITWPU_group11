//
//  QuestionSummaryCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 20/01/26.
//

import UIKit

class QuestionSummaryCell: UITableViewCell {

    // MARK: - Outlets

    // Main Card Container
    @IBOutlet weak var cardContainerView: UIView!

    // Header
    @IBOutlet weak var questionNumberLabel: UILabel!
    @IBOutlet weak var questionTextLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!

    // Options Section
    @IBOutlet weak var optionsContainerView: UIView!
    @IBOutlet var optionViews: [UIView]!
    @IBOutlet var optionLabels: [UILabel]!
    @IBOutlet var optionIcons: [UIImageView]!

    // Footer
    @IBOutlet weak var statusBadgeView: UIView!
    @IBOutlet weak var statusIconImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var difficultyLabel: UILabel!

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupInitialUI()
    }

    private func setupInitialUI() {

        backgroundColor = .clear
        selectionStyle = .none
        
        cardContainerView.backgroundColor = .secondarySystemGroupedBackground
        cardContainerView.layer.cornerRadius = 16 // Increased radius for modern look
        cardContainerView.clipsToBounds = true
        
        // 2. Options Container Styling
        optionsContainerView.layer.cornerRadius = 12
        optionsContainerView.clipsToBounds = true
        optionsContainerView.backgroundColor = .clear // Let the rows stand out instead

        // 3. Individual Option Styling
        for view in optionViews {
            view.layer.cornerRadius = 10
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor.clear.cgColor
        }

        // 4. Footer Status Badge Styling
        statusBadgeView.layer.cornerRadius = 8
    }

    // MARK: - Configuration
    func configure(with item: QuizSummaryItem, index: Int, isExpanded: Bool) {
        // 1. Header
        questionNumberLabel.text = "Question \(index + 1)"
        questionTextLabel.text = item.questionText
        let chevronName = isExpanded ? "chevron.up" : "chevron.down"
        chevronImageView.image = UIImage(systemName: chevronName)

        // 2. Options Section Visibility
        optionsContainerView.isHidden = !isExpanded

        // 3. Reset & Configure Options
        let prefixes = ["A. ", "B. ", "C. ", "D. "]
        for (i, label) in optionLabels.enumerated() {
            
            // ✅ FIX: Set a default background color (Adaptive Grey) instead of .clear
            optionViews[i].backgroundColor = UIColor.secondarySystemFill
            optionViews[i].layer.borderColor = UIColor.clear.cgColor
            
            label.textColor = .label // Standard adaptive text color
            label.font = UIFont.systemFont(ofSize: 15)
            optionIcons[i].isHidden = true

            if i < item.allOptions.count {
                label.text = prefixes[i] + item.allOptions[i]
                label.superview?.isHidden = false

                // Styling Logic for Correct/Wrong
                if i == item.correctAnswerIndex {
                    // Correct Answer: Green styling
                    applyStyle(to: i, color: .systemGreen, iconName: "checkmark.circle.fill")
                } else if let userIndex = item.userAnswerIndex, userIndex == i, !item.isCorrect {
                    // Wrong User Selection: Red styling
                    applyStyle(to: i, color: .systemRed, iconName: "xmark.circle.fill")
                }
            } else {
                // Hide unused option rows
                label.superview?.isHidden = true
            }
        }

        // 4. Footer Status
        if item.isCorrect {
            configureStatus(label: "Correct", color: .systemGreen, icon: "checkmark.circle.fill")
        } else {
            configureStatus(label: "Wrong", color: .systemRed, icon: "xmark.circle.fill")
        }
    }

    // MARK: - Helpers
    private func applyStyle(to index: Int, color: UIColor, iconName: String) {
        optionViews[index].layer.borderColor = color.cgColor
        // Use a slightly stronger background for selected items
        optionViews[index].backgroundColor = color.withAlphaComponent(0.15)
        optionLabels[index].textColor = color
        optionLabels[index].font = UIFont.boldSystemFont(ofSize: 15)
        optionIcons[index].image = UIImage(systemName: iconName)
        optionIcons[index].tintColor = color
        optionIcons[index].isHidden = false
    }

    private func configureStatus(label: String, color: UIColor, icon: String) {
        statusBadgeView.backgroundColor = color.withAlphaComponent(0.15)
        statusLabel.text = label
        statusLabel.textColor = color
        statusIconImageView.image = UIImage(systemName: icon)
        statusIconImageView.tintColor = color
    }
}
