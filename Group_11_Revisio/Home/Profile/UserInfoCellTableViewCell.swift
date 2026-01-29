import UIKit
class UserInfoCell: UICollectionViewCell { // Changed from UITableViewCell
    @IBOutlet weak var pfp: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet var ProfileCard: UIView!
    @IBOutlet weak var editButton: UIButton!
    
    var didTapEdit: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        pfp.layer.cornerRadius = pfp.frame.height / 2
        pfp.layer.borderWidth = 1
        pfp.layer.borderColor = UIColor.systemGray2.cgColor
        
        editButton.layer.cornerRadius = editButton.frame.height / 2
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        ProfileCard.layer.cornerRadius = 17
    }
    
    func configure(name: String, email: String) {
        nameLabel.text = name
        emailLabel.text = email
    }
    
    @objc func editTapped() { didTapEdit?() }
}
