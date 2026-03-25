//
//  ExpandableFileCell.swift
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
    private let statusLabel = UILabel() // "Waiting...", "Analyzing...", or "5 Selected"
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
        
        // 1. Main Container (Background)
        mainContainer.backgroundColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .secondarySystemGroupedBackground : .systemGray6
        }
        
        // ✅ Corner Radius
        mainContainer.layer.cornerRadius = 12
        mainContainer.clipsToBounds = true
        
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainContainer)
        
        // 2. Header Stack
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        statusLabel.font = .systemFont(ofSize: 13, weight: .regular)
        
        chevronImageView.image = UIImage(systemName: "chevron.down")
        chevronImageView.tintColor = .secondaryLabel
        chevronImageView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        chevronImageView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        
        headerStack.addArrangedSubview(iconImageView)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(statusLabel)
        headerStack.addArrangedSubview(chevronImageView)
        
        mainContainer.addSubview(headerStack)
        
        // 3. Topics Container
        topicsContainer.axis = .vertical
        topicsContainer.spacing = 0 // Clean list look
        topicsContainer.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.addSubview(topicsContainer)
        
        // 4. Constraints (Edge-to-Edge, No External Padding)
        NSLayoutConstraint.activate([
            // Main container spans full width of the cell
            mainContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 1), // Tiny gap for separator effect
            mainContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            mainContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            mainContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1),
            
            // Header Internal Padding (So text isn't on the edge of the screen)
            headerStack.topAnchor.constraint(equalTo: mainContainer.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor, constant: 20),
            headerStack.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor, constant: -20),
            headerStack.heightAnchor.constraint(equalToConstant: 24),
            
            // Topics Container Layout
            topicsContainer.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16),
            topicsContainer.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor, constant: 0),
            topicsContainer.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor, constant: 0),
            topicsContainer.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor, constant: -8)
        ])
    }
    
    // MARK: - Configuration
    func configure(with file: UploadedFileModel, index: Int) {
        self.fileIndex = index
        
        // --- START CLEANING LOGIC ---
        // Extract the raw filename from the URL
        let rawName = file.url.lastPathComponent
        
        // Remove extensions, prefixes, and replace underscores with spaces
        let cleanName = rawName.replacingOccurrences(of: ".txt", with: "")
                               .replacingOccurrences(of: "Note_", with: "")
                               .replacingOccurrences(of: "Link_", with: "")
                               .replacingOccurrences(of: "Image_", with: "")
                               .replacingOccurrences(of: "Filtered_", with: "")
                               .replacingOccurrences(of: "_", with: " ")
        
        // Apply the clean name to the label
        titleLabel.text = cleanName
        // --- END CLEANING LOGIC ---
        
        // ✅ ICON LOGIC
        iconImageView.image = UIImage(systemName: file.iconName)
        iconImageView.tintColor = .systemIndigo
        
        // ✅ Status Logic
        if file.isWaiting {
            statusLabel.text = "Waiting..."
            statusLabel.textColor = .systemOrange
            chevronImageView.isHidden = true
        } else if file.isAnalyzing {
            statusLabel.text = "Analyzing..."
            statusLabel.textColor = .systemIndigo
            chevronImageView.isHidden = true
        } else if file.topics.isEmpty {
            statusLabel.text = "No topics found"
            statusLabel.textColor = .secondaryLabel
            chevronImageView.isHidden = true
        } else {
            let selectedCount = file.selectedTopicIndices.count
            statusLabel.text = "\(selectedCount)/\(file.topics.count) Selected"
            statusLabel.textColor = .secondaryLabel
            chevronImageView.isHidden = false
            
            // Rotate chevron based on expanded state
            let rotationAngle: CGFloat = file.isExpanded ? .pi : 0
            chevronImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
        }
        
        // Topics List Logic
        topicsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        topicsContainer.isHidden = !file.isExpanded
        
        if file.isExpanded {
            // Add Divider
            let divider = UIView()
            divider.backgroundColor = .systemGray5
            divider.translatesAutoresizingMaskIntoConstraints = false
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            topicsContainer.addArrangedSubview(divider)
            
            // Add "Select topics" label
            let headerContainer = UIView()
            headerContainer.translatesAutoresizingMaskIntoConstraints = false
            let selectTopicsLabel = UILabel()
            selectTopicsLabel.text = "Select topics to study:"
            selectTopicsLabel.font = .systemFont(ofSize: 14, weight: .semibold)
            selectTopicsLabel.textColor = .secondaryLabel
            selectTopicsLabel.translatesAutoresizingMaskIntoConstraints = false
            headerContainer.addSubview(selectTopicsLabel)
            
            NSLayoutConstraint.activate([
                selectTopicsLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 16),
                selectTopicsLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 4),
                selectTopicsLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 20),
                selectTopicsLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -20)
            ])
            topicsContainer.addArrangedSubview(headerContainer)
            
            // Add Individual Topic Rows
            for (i, topic) in file.topics.enumerated() {
                let row = createTopicRow(title: topic, isSelected: file.selectedTopicIndices.contains(i), topicIndex: i)
                topicsContainer.addArrangedSubview(row)
            }
        }
    }
    
    private func createTopicRow(title: String, isSelected: Bool, topicIndex: Int) -> UIView {
        let paddingContainer = UIView()
        
        // 1. Container matches `optionViews[i]`
        let container = UIView()
        container.layer.cornerRadius = 10
        container.layer.borderWidth = 1
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let indigoColor = UIColor.systemIndigo
        
        if isSelected {
            container.backgroundColor = indigoColor.withAlphaComponent(0.15)
            container.layer.borderColor = indigoColor.cgColor
        } else {
            container.backgroundColor = UIColor.secondarySystemFill
            container.layer.borderColor = UIColor.clear.cgColor
        }
        
        // 2. Horizontal Stack
        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        let topicTitleLabel = UILabel()
        topicTitleLabel.text = title
        topicTitleLabel.font = isSelected ? UIFont.boldSystemFont(ofSize: 15) : UIFont.systemFont(ofSize: 15)
        topicTitleLabel.textColor = isSelected ? indigoColor : .label
        topicTitleLabel.numberOfLines = 0
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "checkmark.circle.fill")
        iconImageView.tintColor = indigoColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.isHidden = !isSelected
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        hStack.addArrangedSubview(topicTitleLabel)
        hStack.addArrangedSubview(iconImageView)
        
        container.addSubview(hStack)
        
        // Stack padding matching `Opt-A-Stack` (leading/trailing 12, top/bottom 8)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
        ])
        
        paddingContainer.addSubview(container)
        
        // Button Over Container
        let button = UIButton(type: .custom)
        button.tag = topicIndex
        button.addTarget(self, action: #selector(topicTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        paddingContainer.addSubview(button)
        
        // Add outer padding Constraints so the options aren't touching each other
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: paddingContainer.topAnchor, constant: 6),
            container.bottomAnchor.constraint(equalTo: paddingContainer.bottomAnchor, constant: -6),
            container.leadingAnchor.constraint(equalTo: paddingContainer.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: paddingContainer.trailingAnchor, constant: -20),
            
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return paddingContainer
    }
    
    
    @objc private func topicTapped(_ sender: UIButton) {
        delegate?.didToggleTopic(fileIndex: self.fileIndex, topicIndex: sender.tag)
    }
}
