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
    }
    
    // MARK: - Advanced Configuration
    func configure(with task: LearningTask) {
        // 1. Set Title
        titleLabel.text = task.title
        
        // 2. Dynamic Subtitle: "X modules remaining"
        // This replaces the static "Notes" text
        subtitleLabel.text = "\(task.remainingModules) modules remaining"
        subtitleLabel.textColor = .secondaryLabel
        
        // 3. Icon Logic (The Switch Statement)
        let symbolname: String
        let iconColor: UIColor
        
        switch task.type {
        case .quiz:
            symbolname = "checklist.checked" // Quiz Icon
            iconColor = .systemOrange
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
        
        // 5. Optional: Add a light background tint behind the icon
        if let container = iconContainerView {
            container.backgroundColor = iconColor.withAlphaComponent(0.15)
            container.layer.cornerRadius = 8
        }
    }
}
