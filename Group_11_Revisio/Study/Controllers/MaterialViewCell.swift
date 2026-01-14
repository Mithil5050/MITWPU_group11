import UIKit

class MaterialViewCell: UITableViewCell {

    // MARK: - Outlets
    // These must match the IDs in the XIB code I provided
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        
        // 1. Transparent Cell Background
        self.backgroundColor = .clear
        
        // 2. Card Styling (Matches LearningTaskCell)
        self.contentView.backgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .secondarySystemGroupedBackground
            } else {
                return UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // #F5F5F5
            }
        }
        
        self.contentView.layer.cornerRadius = 12
        self.contentView.layer.masksToBounds = true
    }
    
    // 3. Spacing for 60pt Row Height
    override func layoutSubviews() {
        super.layoutSubviews()
        // We use a bottom inset of 8pts to create the "card" gap
        // Change bottom from 16 or 8 to exactly 6
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 6, right: 0))
    }
    
    // MARK: - Configuration
    func configure(with item: StudyItem) {
        let symbolname: String
        let iconColor: UIColor
        
        switch item {
        case .topic(let topic):
            titleLabel.text = topic.name
            subtitleLabel.text = "\(topic.materialType) • \(topic.lastAccessed)"
            
            // Replicating icon logic from LearningTaskCell
            switch topic.materialType {
            case "Quiz":
                symbolname = "timer"
                iconColor = UIColor(red: 0.45, green: 0.85, blue: 0.61, alpha: 1.0) // Green
            case "Notes":
                symbolname = "book.pages"
                iconColor = UIColor(hex: "FFC445", alpha: 0.75)
            case "Flashcards":
                symbolname = "rectangle.on.rectangle.angled"
                iconColor =  UIColor(hex: "91C1EF")

            case "Cheatsheet":
                symbolname = "list.clipboard"
                iconColor = UIColor(hex: "8A38F5", alpha: 0.50)
            default:
                symbolname = "doc.text.fill"
                iconColor = .systemGray
            }
            
        case .source(let source):
            titleLabel.text = source.name
            subtitleLabel.text = "\(source.fileType) • \(source.size)"
            symbolname = source.fileType == "Video" ? "play.tv.fill" : "link"
            iconColor = .systemIndigo
        }
        
        // Apply Visuals
        iconImageView.image = UIImage(systemName: symbolname)
        iconImageView.tintColor = iconColor
        iconContainerView.backgroundColor = iconColor.withAlphaComponent(0.15)
        iconContainerView.layer.cornerRadius = 8
    }
}
