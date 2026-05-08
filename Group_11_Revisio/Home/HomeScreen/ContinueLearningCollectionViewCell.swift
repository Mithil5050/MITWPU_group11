import UIKit

protocol ContinueLearningCellDelegate: AnyObject {
    func didSelectLearningItem(_ topic: Topic)
}

class ContinueLearningCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: ContinueLearningCellDelegate?
    private var currentTopic: Topic?
    
    // MARK: - UI Components

    // Small pill label — no separate container view, use a custom PillLabel
    private let tagLabel: PillLabel = {
        let label = PillLabel(hPad: 8, vPad: 4)
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let iconContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 22
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Progress"
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.trackTintColor = UIColor.white.withAlphaComponent(0.12)
        pv.layer.cornerRadius = 3
        pv.clipsToBounds = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private lazy var resumeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Resume", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
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
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.layer.cornerRadius = 18
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor { t in
            t.userInterfaceStyle == .dark ? .secondarySystemGroupedBackground : UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        }
        
        contentView.addSubview(tagLabel)
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(progressTitleLabel)
        contentView.addSubview(percentageLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(resumeButton)
        contentView.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // Tag pill — top left
            tagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            tagLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            tagLabel.heightAnchor.constraint(equalToConstant: 24),
            tagLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            
            // Icon — top right, circular
            iconContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            iconContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            // Title — below the tag with comfortable spacing
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: iconContainer.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: tagLabel.bottomAnchor, constant: 8),
            
            // Progress row
            progressTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            progressTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            
            percentageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            percentageLabel.centerYAnchor.constraint(equalTo: progressTitleLabel.centerYAnchor),
            
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            progressView.topAnchor.constraint(equalTo: progressTitleLabel.bottomAnchor, constant: 6),
            progressView.heightAnchor.constraint(equalToConstant: 5),
            
            // Resume button — fixed height, full width, pinned to bottom
            resumeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            resumeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            resumeButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 14),
            resumeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
            resumeButton.heightAnchor.constraint(equalToConstant: 42),
        ])
    }
    
    // MARK: - Configure
    func configure(with topic: Topic) {
        self.currentTopic = topic
        emptyLabel.isHidden = true
        [tagLabel, titleLabel, progressTitleLabel, percentageLabel, progressView, resumeButton, iconContainer].forEach { $0.isHidden = false }
        
        // Clean display name
        let displayName: String
        if let src = topic.sourceName, !src.isEmpty {
            displayName = src
        } else {
            displayName = topic.name
                .replacingOccurrences(of: ".txt", with: "")
                .replacingOccurrences(of: ".pdf", with: "")
                .replacingOccurrences(of: "Note_", with: "")
                .replacingOccurrences(of: "Quiz_", with: "")
                .replacingOccurrences(of: "Flashcard_", with: "")
                .replacingOccurrences(of: "Link_", with: "")
        }
        titleLabel.text = displayName
        
        // Tag shows folder name
        tagLabel.text = topic.parentSubjectName.isEmpty ? topic.materialType : topic.parentSubjectName
        
        // Brand colors from LearningTaskCell
        let typeLower = topic.materialType.lowercased()
        let accent: UIColor
        let symbol: String
        
        if typeLower.contains("quiz") {
            accent = UIColor(red: 136/255, green: 215/255, blue: 105/255, alpha: 1.0) // #88D769
            symbol = "timer"
        } else if typeLower.contains("flashcard") {
            accent = UIColor(red: 145/255, green: 193/255, blue: 239/255, alpha: 1.0) // #91C1EF
            symbol = "rectangle.on.rectangle.angled"
        } else if typeLower.contains("cheatsheet") {
            accent = UIColor(red: 138/255, green: 56/255, blue: 245/255, alpha: 0.85)
            symbol = "list.clipboard"
        } else if typeLower.contains("note") {
            accent = UIColor(red: 255/255, green: 196/255, blue: 69/255, alpha: 0.85)
            symbol = "book.pages"
        } else {
            accent = .systemGray
            symbol = "graduationcap.fill"
        }
        
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconImageView.image = UIImage(systemName: symbol, withConfiguration: cfg)
        iconImageView.tintColor = accent
        iconContainer.backgroundColor = accent.withAlphaComponent(0.15)
        
        tagLabel.textColor = accent
        tagLabel.backgroundColor = accent.withAlphaComponent(0.15)
        
        progressView.progressTintColor = accent
        percentageLabel.textColor = accent
        
        resumeButton.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        resumeButton.setTitleColor(accent, for: .normal)
        
        // Progress
        let current = topic.currentProgressIndex ?? 0
        let total = topic.totalItemsCount ?? (topic.quizQuestions?.count ?? 10)
        let val = total > 0 ? Float(current) / Float(total) : 0.0
        progressView.progress = val
        percentageLabel.text = "\(Int(val * 100))%"
    }
    
    func configureAsEmpty() {
        currentTopic = nil
        emptyLabel.isHidden = false
        [tagLabel, titleLabel, progressTitleLabel, percentageLabel, progressView, resumeButton, iconContainer].forEach { $0.isHidden = true }
    }
    
    @objc private func resumeTapped() {
        guard let topic = currentTopic else { return }
        delegate?.didSelectLearningItem(topic)
    }
}

// MARK: - PillLabel: self-sizing label with internal padding and rounded corners
final class PillLabel: UILabel {
    private let hPad: CGFloat
    private let vPad: CGFloat
    
    init(hPad: CGFloat = 8, vPad: CGFloat = 0) {
        self.hPad = hPad
        self.vPad = vPad
        super.init(frame: .zero)
        clipsToBounds = true
        textAlignment = .center
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + hPad * 2, height: s.height)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: hPad, dy: 0))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 10
    }
}
