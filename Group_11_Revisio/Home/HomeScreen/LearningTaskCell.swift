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
            
            // 1. Transparent Cell Background (Container)
            self.backgroundColor = .clear
            
            // 2. Dynamic Card Styling on ContentView
            // Uses #F5F5F5 in Light Mode, and System Dark Gray in Dark Mode
            self.contentView.backgroundColor = UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return .secondarySystemGroupedBackground // Dark card look
                } else {
                    return UIColor(hex: "F5F5F5") // Your custom light gray
                }
            }
            
            self.contentView.layer.cornerRadius = 12
            self.contentView.layer.masksToBounds = true
        }
    
    // 3. Add Spacing Between Cells (Card Effect)
    override func layoutSubviews() {
        super.layoutSubviews()
        // Adds 8pts of vertical spacing between cells so they look like separate cards
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0))
    }
    
    // MARK: - Advanced Configuration
    func configure(with task: LearningTask) {
        // 1. Set Title
        titleLabel.text = task.title
        
        // 2. Dynamic Subtitle: "X modules remaining"
        subtitleLabel.text = "\(task.remainingModules) modules remaining"
        subtitleLabel.textColor = .secondaryLabel
        
        // 3. Icon Logic (Updated for Quiz Timer)
        let symbolname: String
        let iconColor: UIColor
        
        switch task.type {
        case .quiz:
            symbolname = "timer" // 🆕 Changed icon
            iconColor = UIColor(hex: "74DA9B") // 🆕 Changed color
        case .notes:
            symbolname = "book.pages.fill"   // Notes Icon
            iconColor = .systemBlue
        case .video:
            symbolname = "play.tv.fill"      // Video Icon
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
