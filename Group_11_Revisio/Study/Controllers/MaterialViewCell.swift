import UIKit

class MaterialViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconContainerView: UIView!
    var onInfoButtonTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .default
        
        let clearView = UIView()
        clearView.backgroundColor = .clear
        self.selectedBackgroundView = clearView
        
        self.backgroundColor = .clear
        
        self.contentView.backgroundColor = .systemGray6
        self.contentView.layer.cornerRadius = 12
        
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.borderColor = UIColor.separator.cgColor
        
        self.contentView.clipsToBounds = true
        
        // ✅ LOGIC CHANGE: Enable Word Wrap and Disable Hyphenation for list titles
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.allowsDefaultTighteningForTruncation = true
    }
    
    @IBAction func infoButtonAction(_ sender: UIButton) {
        onInfoButtonTapped?()
    }
    
    func configure(with item: StudyItem) {
        let symbolname: String
        let iconColor: UIColor
        let rawName: String
        
        switch item {
        case .topic(let topic):
            rawName = topic.name
            subtitleLabel.text = "\(topic.materialType) • \(topic.lastAccessed)"
            
            switch topic.materialType {
            case "Quiz":
                symbolname = "timer"
                iconColor = UIColor(red: 0.45, green: 0.85, blue: 0.61, alpha: 1.0)
            case "Notes":
                symbolname = "book.pages"
                iconColor = UIColor(hex: "FFC445", alpha: 0.75)
            case "Flashcards":
                symbolname = "rectangle.on.rectangle.angled"
                iconColor = UIColor(hex: "91C1EF")
            case "Cheatsheet":
                symbolname = "list.clipboard"
                iconColor = UIColor(hex: "8A38F5", alpha: 0.50)
            default:
                symbolname = "doc.text.fill"
                iconColor = .systemGray
            }
            
        case .source(let source):
            rawName = source.name
            iconColor = .systemIndigo
            
            let type = source.fileType.uppercased()
            
            if type == "LINK" || type == "URL" {
                symbolname = "link"
                subtitleLabel.text = "Web Link"
            } else if type == "IMAGE" || type == "JPG" || type == "PNG" || type == "JPEG" {
                symbolname = "photo.fill"
                subtitleLabel.text = "\(type) • \(source.size)"
            } else if type == "DOC" || type == "PDF" {
                symbolname = "doc.richtext.fill"
                subtitleLabel.text = "\(type) • \(source.size)"
            } else if type == "TEXT" || type == "TXT" {
                symbolname = "textformat"
                subtitleLabel.text = "\(type) • \(source.size)"
            } else {
                symbolname = "link"
                subtitleLabel.text = "\(type) • \(source.size)"
            }
        }
        
        // ✅ LOGIC CHANGE: Clean the display name (Remove Note_, .txt, and underscores)
        let cleanName = rawName.replacingOccurrences(of: ".txt", with: "")
                               .replacingOccurrences(of: "Note_", with: "")
                               .replacingOccurrences(of: "Link_", with: "")
                               .replacingOccurrences(of: "Image_", with: "")
                               .replacingOccurrences(of: "_", with: " ")
                               .trimmingCharacters(in: .whitespaces)
        
        titleLabel.text = cleanName
        
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
