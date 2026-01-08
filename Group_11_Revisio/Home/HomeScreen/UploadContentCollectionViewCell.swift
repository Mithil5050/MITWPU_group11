import UIKit

// MARK: - Delegate Protocol
protocol UploadContentCellDelegate: AnyObject {
    func uploadCellDidTapDocument(_ cell: UploadContentCollectionViewCell)
    func uploadCellDidTapMedia(_ cell: UploadContentCollectionViewCell)
    func uploadCellDidTapLink(_ cell: UploadContentCollectionViewCell)
    func uploadCellDidTapText(_ cell: UploadContentCollectionViewCell)
}

// MARK: - Collection View Cell
class UploadContentCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    weak var delegate: UploadContentCellDelegate?
    
    private var items: [ContentItem] = []
    
    // If you have outlets (labels, icons, etc.), declare them here and connect in the XIB.
    // @IBOutlet weak var titleLabel: UILabel!
    // @IBOutlet weak var stackView: UIStackView!
    @IBOutlet var ViewCard: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Style the cell if needed
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .systemGray6
        ViewCard.backgroundColor = UIColor(hex: "F5F5F5")
    }
    
    // Configure the cell with any data you want to show (e.g., recent uploads list)
    func configure(with items: [ContentItem]) {
        self.items = items
        // Update UI from items as needed
        // Example: titleLabel.text = "Upload Content"
    }
    
    // MARK: - Button Actions (connect these in the XIB)
    @IBAction func documentButtonTapped(_ sender: UIButton) {
        delegate?.uploadCellDidTapDocument(self)
    }
    
    @IBAction func mediaButtonTapped(_ sender: UIButton) {
        delegate?.uploadCellDidTapMedia(self)
    }
    
    @IBAction func linkButtonTapped(_ sender: UIButton) {
        delegate?.uploadCellDidTapLink(self)
    }
    
    @IBAction func textButtonTapped(_ sender: UIButton) {
        delegate?.uploadCellDidTapText(self)
    }
}
