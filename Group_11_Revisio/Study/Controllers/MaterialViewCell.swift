import UIKit

class MaterialViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Restore your original clean look
        self.selectionStyle = .default
        self.tintColor = .systemBlue
        self.backgroundColor = .clear
        
        // This puts your gray card background back
        self.contentView.backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .secondarySystemGroupedBackground : UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        }
        
        self.contentView.layer.cornerRadius = 12
        self.contentView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // This restores the vertical gap between your cards
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 6, right: 0))
    }
    
    func configure(with item: StudyItem) {
        // ... (Keep your existing configure logic for icons/text) ...
        let symbolname: String
        let iconColor: UIColor
        
        switch item {
        case .topic(let topic):
            titleLabel.text = topic.name
            subtitleLabel.text = "\(topic.materialType) • \(topic.lastAccessed)"
            
            switch topic.materialType {
            case "Quiz":
                symbolname = "timer"; iconColor = UIColor(red: 0.45, green: 0.85, blue: 0.61, alpha: 1.0)
            case "Notes":
                symbolname = "book.pages"; iconColor = UIColor(hex: "FFC445", alpha: 0.75)
            case "Flashcards":
                symbolname = "rectangle.on.rectangle.angled"; iconColor =  UIColor(hex: "91C1EF")
            case "Cheatsheet":
                symbolname = "list.clipboard"; iconColor = UIColor(hex: "8A38F5", alpha: 0.50)
            default:
                symbolname = "doc.text.fill"; iconColor = .systemGray
            }
            
        case .source(let source):
            titleLabel.text = source.name
            subtitleLabel.text = "\(source.fileType) • \(source.size)"
            symbolname = source.fileType == "Video" ? "play.tv.fill" : "link"
            iconColor = .systemIndigo
        }
        
        iconImageView.image = UIImage(systemName: symbolname)
        iconImageView.tintColor = iconColor
        iconContainerView.backgroundColor = iconColor.withAlphaComponent(0.15)
        iconContainerView.layer.cornerRadius = 8
    }

    // DELETE any setEditing function here so it doesn't mess up the background
}
