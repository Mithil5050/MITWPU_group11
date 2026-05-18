import UIKit

class TopicCardCell: UITableViewCell {

    @IBOutlet var cardContainerView: UIView!

    @IBOutlet var iconImageView: UIImageView!

    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var subtitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        cardContainerView.backgroundColor = .cardBackgroundColor
        cardContainerView.layer.cornerRadius = 8.0
        cardContainerView.clipsToBounds = true
    }

}
