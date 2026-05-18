//
//  SettingsCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/01/26.
//


import UIKit

class SettingsCell: UICollectionViewCell {

    // MARK: - Outlets
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    @IBOutlet weak var chevronView: UIImageView!
    @IBOutlet weak var separatorView: UIView!

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        self.backgroundColor = .secondarySystemGroupedBackground

        titleLabel.textColor = .label
        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)

        switchControl.onTintColor = .systemGreen
        chevronView.tintColor = .systemGray
    }

    // MARK: - Configuration
    func configure(title: String, icon: String, color: UIColor, isSwitch: Bool) {
        titleLabel.text = title
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = color

        if isSwitch {
            switchControl.isHidden = false
            chevronView.isHidden = true
            // In a real app, you'd set switchControl.isOn based on saved preferences here
        } else {
            switchControl.isHidden = true
            chevronView.isHidden = false
        }
    }
}
