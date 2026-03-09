//
//  GroupCell.swift
//  Group_11_Revisio
//

import UIKit

class GroupCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        self.accessoryType = .disclosureIndicator
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // Called from GroupsViewController — pass nil/empty for default icon
    func configureAvatar(_ avatarUrl: String?) {
        if let urlString = avatarUrl, !urlString.isEmpty, let url = URL(string: urlString) {
            avatarImageView.image = UIImage(systemName: "person.3.fill")
            avatarImageView.tintColor = .systemGray3
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.avatarImageView.image = img
                    self?.avatarImageView.tintColor = nil
                }
            }.resume()
        } else {
            avatarImageView.image = UIImage(systemName: "person.3.fill")
            avatarImageView.tintColor = .systemGray3
        }
    }
}
