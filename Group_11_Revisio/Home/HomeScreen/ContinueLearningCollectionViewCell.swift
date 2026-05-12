import UIKit

protocol ContinueLearningCellDelegate: AnyObject {
    func didSelectLearningItem(_ topic: Topic)
    func didTapStartLearning()
}

class ContinueLearningCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: ContinueLearningCellDelegate?
    private var currentTopic: Topic?
    
    // MARK: - UI Components (Normal State)
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
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressRowStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
    
    // MARK: - UI Components (Empty State)
    private let emptyContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemThinMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        return view
    }()
    
    private let mascotImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bot_pencil")
        
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Ready to Start"
        label.textColor = .white
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emptySubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Generate material to\ntrack your progress"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Start", for: .normal)
        btn.backgroundColor = UIColor(red: 109/255, green: 91/255, blue: 255/255, alpha: 1.0)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.layer.cornerRadius = 22
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        return btn
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
        
        // Base background color
        contentView.backgroundColor = UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0)
        
        // Add normal state views
        [tagLabel, iconContainer, titleLabel, progressRowStack, progressView, resumeButton].forEach {
            contentView.addSubview($0)
        }
        iconContainer.addSubview(iconImageView)
        progressRowStack.addArrangedSubview(progressTitleLabel)
        progressRowStack.addArrangedSubview(percentageLabel)
        progressTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        percentageLabel.setContentHuggingPriority(.required, for: .horizontal)
        percentageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // Add empty state views
        contentView.addSubview(emptyContainer)
        emptyContainer.addSubview(blurView)
        emptyContainer.addSubview(mascotImageView)
        emptyContainer.addSubview(emptyTitleLabel)
        emptyContainer.addSubview(emptySubtitleLabel)
        emptyContainer.addSubview(startButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Normal state constraints
            tagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            tagLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            tagLabel.heightAnchor.constraint(equalToConstant: 24),
            
            iconContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            iconContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: iconContainer.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: tagLabel.bottomAnchor, constant: 12),
            
            progressRowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            progressRowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            progressRowStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            progressView.topAnchor.constraint(equalTo: progressRowStack.bottomAnchor, constant: 8),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            
            resumeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            resumeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            resumeButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            resumeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
            resumeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Empty state container - matches content view
            emptyContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            emptyContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emptyContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emptyContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            blurView.topAnchor.constraint(equalTo: emptyContainer.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: emptyContainer.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: emptyContainer.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: emptyContainer.bottomAnchor),
            
            mascotImageView.trailingAnchor.constraint(equalTo: emptyContainer.trailingAnchor, constant: 0),
            mascotImageView.bottomAnchor.constraint(equalTo: emptyContainer.bottomAnchor, constant: 0),
            mascotImageView.widthAnchor.constraint(equalTo: emptyContainer.widthAnchor, multiplier: 0.45),
            mascotImageView.heightAnchor.constraint(equalTo: mascotImageView.widthAnchor),
            
            emptyTitleLabel.leadingAnchor.constraint(equalTo: emptyContainer.leadingAnchor, constant: 20),
            emptyTitleLabel.topAnchor.constraint(equalTo: emptyContainer.topAnchor, constant: 24),
            
            emptySubtitleLabel.leadingAnchor.constraint(equalTo: emptyContainer.leadingAnchor, constant: 20),
            emptySubtitleLabel.trailingAnchor.constraint(equalTo: mascotImageView.leadingAnchor, constant: 5),
            emptySubtitleLabel.topAnchor.constraint(equalTo: emptyTitleLabel.bottomAnchor, constant: 12),
            
            startButton.leadingAnchor.constraint(equalTo: emptyContainer.leadingAnchor, constant: 20),
            startButton.bottomAnchor.constraint(equalTo: emptyContainer.bottomAnchor, constant: -24),
            startButton.widthAnchor.constraint(equalToConstant: 160),
            startButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Configure
    func configure(with topic: Topic) {
        self.currentTopic = topic
        emptyContainer.isHidden = true
        [tagLabel, titleLabel, progressRowStack, percentageLabel, progressView, resumeButton, iconContainer].forEach { $0.isHidden = false }
        
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
        tagLabel.text = topic.parentSubjectName.isEmpty ? topic.materialType : topic.parentSubjectName
        
        let typeLower = topic.materialType.lowercased()
        let accent: UIColor
        let symbol: String
        
        if typeLower.contains("quiz") {
            accent = UIColor(red: 136/255, green: 215/255, blue: 105/255, alpha: 1.0)
            symbol = "timer"
        } else if typeLower.contains("flashcard") {
            accent = UIColor(red: 145/255, green: 193/255, blue: 239/255, alpha: 1.0)
            symbol = "rectangle.on.rectangle.angled"
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
        progressTitleLabel.text = "Progress"
        progressTitleLabel.textColor = .white
        resumeButton.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        resumeButton.setTitleColor(accent, for: .normal)
        
        let current = topic.currentProgressIndex ?? 0
        let total = topic.totalItemsCount ?? 10
        let val = total > 0 ? Float(current) / Float(total) : 0.0
        progressView.progress = val
        percentageLabel.text = "\(Int(val * 100))%"
    }
    
    func configureAsEmpty() {
        currentTopic = nil
        emptyContainer.isHidden = false
        [tagLabel, titleLabel, progressRowStack, percentageLabel, progressView, resumeButton, iconContainer].forEach { $0.isHidden = true }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        progressTitleLabel.text = "Progress"
        progressTitleLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        percentageLabel.text = nil
        progressView.progress = 0
        titleLabel.text = nil
        emptyContainer.isHidden = true
    }
    
    @objc private func resumeTapped() {
        guard let topic = currentTopic else { return }
        delegate?.didSelectLearningItem(topic)
    }
    
    @objc private func startTapped() {
        delegate?.didTapStartLearning()
    }
}

// MARK: - PillLabel
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
