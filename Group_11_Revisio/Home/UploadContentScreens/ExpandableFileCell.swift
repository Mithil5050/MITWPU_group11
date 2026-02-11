//
//  ExpandableFileCellDelegate.swift
//  Group_11_Revisio
//
//  Created by Mithil on 11/02/26.
//


import UIKit

protocol ExpandableFileCellDelegate: AnyObject {
    func didToggleTopic(fileIndex: Int, topicIndex: Int)
}

class ExpandableFileCell: UITableViewCell {

    static let identifier = "ExpandableFileCell"
    weak var delegate: ExpandableFileCellDelegate?
    private var fileIndex: Int = 0
    
    // UI Elements
    private let mainContainer = UIView()
    private let headerStack = UIStackView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel() // "Analyzing..." or "5 Topics"
    private let chevronImageView = UIImageView()
    
    // The container for the list of topics (Hidden when collapsed)
    private let topicsContainer = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // 1. Main Card Style
        mainContainer.backgroundColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .secondarySystemGroupedBackground : .systemGray6
        }
        mainContainer.layer.cornerRadius = 12
        mainContainer.clipsToBounds = true
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainContainer)
        
        // 2. Header Stack (Icon + Title + Chevron)
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        statusLabel.font = .systemFont(ofSize: 12, weight: .regular)
        statusLabel.textColor = .secondaryLabel
        
        chevronImageView.image = UIImage(systemName: "chevron.down")
        chevronImageView.tintColor = .secondaryLabel
        chevronImageView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        chevronImageView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        
        headerStack.addArrangedSubview(iconImageView)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(statusLabel)
        headerStack.addArrangedSubview(chevronImageView)
        
        mainContainer.addSubview(headerStack)
        
        // 3. Topics Container (Vertical Stack of Checkboxes)
        topicsContainer.axis = .vertical
        topicsContainer.spacing = 8
        topicsContainer.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.addSubview(topicsContainer)
        
        // 4. Layout Constraints
        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            mainContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            headerStack.topAnchor.constraint(equalTo: mainContainer.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor, constant: 12),
            headerStack.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor, constant: -12),
            headerStack.heightAnchor.constraint(equalToConstant: 30),
            
            topicsContainer.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            topicsContainer.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor, constant: 12),
            topicsContainer.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor, constant: -12),
            topicsContainer.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    func configure(with file: UploadedFileModel, index: Int) {
        self.fileIndex = index
        titleLabel.text = file.url.lastPathComponent
        
        // Icon
        let isPDF = file.url.pathExtension.lowercased() == "pdf"
        iconImageView.image = UIImage(systemName: isPDF ? "doc.text.fill" : "doc.fill")
        iconImageView.tintColor = .systemIndigo
        
        // Status & Chevron Logic
        if file.isAnalyzing {
            statusLabel.text = "Analyzing..."
            statusLabel.textColor = .systemBlue
            chevronImageView.isHidden = true
        } else if file.topics.isEmpty {
            statusLabel.text = "No topics found"
            chevronImageView.isHidden = true
        } else {
            let selectedCount = file.selectedTopicIndices.count
            statusLabel.text = "\(selectedCount)/\(file.topics.count) Selected"
            statusLabel.textColor = .secondaryLabel
            chevronImageView.isHidden = false
            
            // Rotate chevron if expanded
            let rotationAngle: CGFloat = file.isExpanded ? .pi : 0
            chevronImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
        }
        
        // Topics List Logic
        topicsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() } // Clear old views
        topicsContainer.isHidden = !file.isExpanded
        
        if file.isExpanded {
            // Divider Line
            let divider = UIView()
            divider.backgroundColor = .systemGray5
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            topicsContainer.addArrangedSubview(divider)
            
            // Generate rows for topics
            for (i, topic) in file.topics.enumerated() {
                let row = createTopicRow(title: topic, isSelected: file.selectedTopicIndices.contains(i), topicIndex: i)
                topicsContainer.addArrangedSubview(row)
            }
        }
    }
    
    private func createTopicRow(title: String, isSelected: Bool, topicIndex: Int) -> UIView {
        let button = UIButton(type: .custom)
        button.contentHorizontalAlignment = .leading
        
        let iconName = isSelected ? "checkmark.square.fill" : "square"
        button.setImage(UIImage(systemName: iconName), for: .normal)
        button.setTitle("  " + title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.tintColor = isSelected ? .systemBlue : .systemGray3
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.titleLabel?.numberOfLines = 2
        
        // Tag allows us to identify which topic was tapped
        button.tag = topicIndex
        button.addTarget(self, action: #selector(topicTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func topicTapped(_ sender: UIButton) {
        delegate?.didToggleTopic(fileIndex: self.fileIndex, topicIndex: sender.tag)
    }
}