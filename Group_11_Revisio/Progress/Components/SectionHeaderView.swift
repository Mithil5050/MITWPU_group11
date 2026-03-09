//
//  SectionHeaderView.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 19/02/26.
//

import UIKit

class SectionHeaderView: UICollectionReusableView {

    let titleLabel = UILabel()
    private let showAllButton = UIButton(type: .system)

    /// Set this to make the "Show All" button visible and functional.
    /// Leave nil to hide the button (all other sections).
    var showAllHandler: (() -> Void)? {
        didSet { showAllButton.isHidden = showAllHandler == nil }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHeader()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHeader()
    }

    private func setupHeader() {
        // Title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Show All button
        showAllButton.setTitle("Show All", for: .normal)
        showAllButton.setTitleColor(.systemBlue, for: .normal)
        showAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        showAllButton.isHidden = true
        showAllButton.translatesAutoresizingMaskIntoConstraints = false
        showAllButton.addTarget(self, action: #selector(showAllTapped), for: .touchUpInside)
        addSubview(showAllButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: showAllButton.leadingAnchor, constant: -8),

            showAllButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            showAllButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc private func showAllTapped() {
        showAllHandler?()
    }
}
