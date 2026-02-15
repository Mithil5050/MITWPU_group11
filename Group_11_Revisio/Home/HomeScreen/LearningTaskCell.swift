import UIKit

class LearningTaskCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconContainerView: UIView!
    
    override func awakeFromNib() {
            super.awakeFromNib()
            self.selectionStyle = .none
            self.backgroundColor = .clear
            
            self.contentView.backgroundColor = UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return .secondarySystemGroupedBackground
                } else {
                    return UIColor(hex: "F5F5F5")
                }
            }
            
            self.contentView.layer.cornerRadius = 12
            self.contentView.layer.masksToBounds = true
        }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0))
    }
    
    // MARK: - Advanced Configuration
    func configure(with task: LearningTask) {
        // 1. Set Title
        titleLabel.text = task.title
        
        // 2. Dynamic Subtitle
        if task.type == .quiz {
            subtitleLabel.text = "\(task.remainingModules) questions"
        } else {
            subtitleLabel.text = "Tap to review"
        }
        subtitleLabel.textColor = .secondaryLabel
        
        // 3. Icon Logic
        let symbolname: String
        let iconColor: UIColor
        
        switch task.type {
        case .quiz:
            symbolname = "timer"
            iconColor = UIColor(hex: "88D769") // Green
        case .notes:
            symbolname = "book.pages"
            iconColor = UIColor(hex: "FFC445", alpha: 0.75) // Orange
        case .flashcard:
            symbolname = "rectangle.on.rectangle.angled"
            iconColor = UIColor(hex: "91C1EF") // Blue
        case .cheatsheet: // ✅ Purple Clipboard
            symbolname = "list.clipboard"
            iconColor = UIColor(hex: "8A38F5", alpha: 0.50)
        case .video:
            symbolname = "play.tv.fill"
            iconColor = .systemIndigo
        default:
            symbolname = "graduationcap.fill"
            iconColor = .systemGray
        }
        
        // 4. Apply the Icon
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        iconImageView.image = UIImage(systemName: symbolname, withConfiguration: config)
        iconImageView.tintColor = iconColor
        
        // 5. Update container tint
        if let container = iconContainerView {
            container.backgroundColor = iconColor.withAlphaComponent(0.15)
            container.layer.cornerRadius = 8
        }
    }
}
