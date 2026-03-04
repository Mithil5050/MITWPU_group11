//
//  SectionHeaderView.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 19/02/26.
//

import Foundation
import UIKit

class SectionHeaderView: UICollectionReusableView {
    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHeader()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHeader()
    }

    private func setupHeader() {
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // ✅ CHANGED: Set to 0.
            // The Collection View section already pushes everything 16px to the right.
            // By setting this to 0, we stop it from adding another layer of padding!
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
}
