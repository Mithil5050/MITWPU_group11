with open("Group_11_Revisio/Home/HomeScreen/ContinueLearningCollectionViewCell.swift", "r") as f:
    content = f.read()

new_class = """import UIKit

protocol ContinueLearningCellDelegate: AnyObject {
    func didSelectLearningItem(_ topic: Topic)
}

class ContinueLearningCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: ContinueLearningCellDelegate?
    private var currentTopic: Topic?
    
    // MARK: - UI Components
    private let tagContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        view.layer.cornerRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let tagLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let iconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .tertiarySystemGroupedBackground
            } else {
                return .white
            }
        }
        view.layer.cornerRadius = 22
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Progress"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.progressTintColor = .systemBlue
        pv.trackTintColor = UIColor.white.withAlphaComponent(0.1)
        pv.layer.cornerRadius = 3
        pv.clipsToBounds = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private lazy var resumeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Resume", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(resumeTapped), for: .touchUpInside)
        return btn
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Material to continue learning"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.backgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .secondarySystemGroupedBackground
            } else {
                return UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
            }
        }
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true
        
        contentView.addSubview(tagContainer)
        tagContainer.addSubview(tagLabel)
        
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(progressTitleLabel)
        contentView.addSubview(percentageLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(resumeButton)
        contentView.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            // Empty Label
            emptyLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // Tag Container (Top Left)
            tagContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tagContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            
            tagLabel.leadingAnchor.constraint(equalTo: tagContainer.leadingAnchor, constant: 8),
            tagLabel.trailingAnchor.constraint(equalTo: tagContainer.trailingAnchor, constant: -8),
            tagLabel.topAnchor.constraint(equalTo: tagContainer.topAnchor, constant: 4),
            tagLabel.bottomAnchor.constraint(equalTo: tagContainer.bottomAnchor, constant: -4),
            
            // Icon Container (Top Right)
            iconContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            iconContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            
            // Icon ImageView
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            // Title
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: tagContainer.bottomAnchor, constant: 12),
            
            // Progress Labels
            progressTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            progressTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            
            percentageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            percentageLabel.centerYAnchor.constraint(equalTo: progressTitleLabel.centerYAnchor),
            
            // Progress Bar
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            progressView.topAnchor.constraint(equalTo: progressTitleLabel.bottomAnchor, constant: 8),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            
            // Resume Button
            resumeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            resumeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            resumeButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            resumeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            resumeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Configuration
    func configure(with topic: Topic) {
        self.currentTopic = topic
        emptyLabel.isHidden = true
        
        [tagContainer, titleLabel, progressTitleLabel, percentageLabel, progressView, resumeButton, iconContainer].forEach { $0.isHidden = false }
        
        titleLabel.text = topic.name
        
        // Let's use the parentSubjectName for the tag if it's available and user didn't explicitly forbid it in this variant, or the material type.
        // The screenshot shows "Biology" which is a subject. The user previously said "only show material name no folder name".
        // If we use materialType, it'll say "Quiz" or "Flashcard" which is also very useful in that spot.
        tagLabel.text = topic.materialType.uppercased()
        
        // Icon logic based on material type
        let typeLower = topic.materialType.lowercased()
        if typeLower.contains("quiz") {
            iconImageView.image = UIImage(systemName: "questionmark.circle.fill")
        } else if typeLower.contains("flashcard") {
            iconImageView.image = UIImage(systemName: "rectangle.stack.fill")
        } else if typeLower.contains("cheatsheet") || typeLower.contains("note") {
            iconImageView.image = UIImage(systemName: "doc.text.fill")
        } else {
            iconImageView.image = UIImage(systemName: "book.fill") // Default
        }
        
        // Progress Logic
        let current = topic.currentProgressIndex ?? 0
        let total = topic.totalItemsCount ?? 10 // Default
        let progressVal = total > 0 ? Float(current) / Float(total) : 0.0
        
        progressView.progress = progressVal
        percentageLabel.text = "\(Int(progressVal * 100))%"
    }
    
    func configureAsEmpty() {
        self.currentTopic = nil
        emptyLabel.isHidden = false
        [tagContainer, titleLabel, progressTitleLabel, percentageLabel, progressView, resumeButton, iconContainer].forEach { $0.isHidden = true }
    }
    
    @objc private func resumeTapped() {
        guard let topic = currentTopic else { return }
        delegate?.didSelectLearningItem(topic)
    }
}
"""

with open("Group_11_Revisio/Home/HomeScreen/ContinueLearningCollectionViewCell.swift", "w") as f:
    f.write(new_class)
