//
//  WordCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 15/12/25.
//


// WordCell.swift

import UIKit

class WordCell: UICollectionViewCell {
    
    // MARK: UI Components
    private let wordLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    private func setupViews() {
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
        
        contentView.addSubview(wordLabel)
        
        NSLayoutConstraint.activate([
            wordLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            wordLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            wordLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            wordLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4)
        ])
    }
    
    // MARK: Configuration
    func configure(with word: WordModel) {
        wordLabel.text = word.text
        
        if word.isGuessed {
            self.backgroundColor = .clear
            self.wordLabel.textColor = .clear
            self.isUserInteractionEnabled = false
        } else if word.isSelected {
            self.backgroundColor = UIColor(hex: "91C1EF")
            self.wordLabel.textColor = .label // Black/White based on mode
            self.alpha = 1.0
            self.isUserInteractionEnabled = true
        } else {
            // Default state
            self.backgroundColor = .systemGray5 // Light background
            self.wordLabel.textColor = .label
            self.alpha = 1.0
            self.isUserInteractionEnabled = true
        }
    }
}
