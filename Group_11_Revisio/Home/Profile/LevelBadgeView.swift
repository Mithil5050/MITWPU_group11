//
//  LevelBadgeView.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 26/02/26.
//

import Foundation
import UIKit

class LevelBadgeView: UIView {
    private let shieldImageView = UIImageView()
    private let levelNumberLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // Shield Icon
        shieldImageView.image = UIImage(systemName: "shield.fill")
        shieldImageView.tintColor = .systemBlue
        shieldImageView.contentMode = .scaleAspectFit
        shieldImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(shieldImageView)

        // Number Label centered in shield
        levelNumberLabel.textColor = .white
        levelNumberLabel.font = .systemFont(ofSize: 16, weight: .bold)
        levelNumberLabel.textAlignment = .center
        levelNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(levelNumberLabel)

        NSLayoutConstraint.activate([
            shieldImageView.topAnchor.constraint(equalTo: topAnchor),
            shieldImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            shieldImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shieldImageView.trailingAnchor.constraint(equalTo: trailingAnchor),

            levelNumberLabel.centerXAnchor.constraint(equalTo: shieldImageView.centerXAnchor),
            levelNumberLabel.centerYAnchor.constraint(equalTo: shieldImageView.centerYAnchor, constant: 1)
        ])
    }

    func setLevel(_ level: Int) {
        levelNumberLabel.text = "\(level)"
    }
}
