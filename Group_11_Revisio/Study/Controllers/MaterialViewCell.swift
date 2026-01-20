import UIKit

class MaterialViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .default // Required for the blue tick
        
        // This removes the gray 'box' highlight
        let clearView = UIView()
        clearView.backgroundColor = .clear
        self.selectedBackgroundView = clearView
        
        // Your existing card styling
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .secondarySystemGroupedBackground // Or your #F5F5F5
        self.contentView.layer.cornerRadius = 12
    }
    
    
    func configure(with item: StudyItem) {
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
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bottomGap: CGFloat = 6
        contentView.frame = CGRect(
            x: 0,
            y: 0,
            width: self.bounds.width,
            height: self.bounds.height - bottomGap
        )
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.applyInternalShift(isEditing: editing)
                self.layoutIfNeeded()
            }
        } else {
            self.applyInternalShift(isEditing: editing)
        }
    }

    private func applyInternalShift(isEditing: Bool) {
        let shift: CGFloat = isEditing ? 60 : 16
        self.contentView.layoutMargins = UIEdgeInsets(top: 0, left: shift, bottom: 0, right: 16)
    }

}

    
