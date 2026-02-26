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
    let showAllButton = UIButton(type: .system)
    var onShowAllTapped: (() -> Void)?

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
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        
        showAllButton.setTitle("Show All", for: .normal)
        showAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        showAllButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        addSubview(titleLabel)
        addSubview(showAllButton)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        showAllButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            showAllButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            showAllButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    @objc private func buttonTapped() {
        onShowAllTapped?()
    }
}
