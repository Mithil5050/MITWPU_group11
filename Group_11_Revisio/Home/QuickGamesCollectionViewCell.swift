// QuickGamesCollectionViewCell.swift

import UIKit

class QuickGamesCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var gameCard: UIView!
    // ➡️ Connect these outlets from QuickGamesCollectionViewCell.xib
    @IBOutlet weak var gameImage: UIImageView!
    @IBOutlet weak var gameTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        gameCard.layer.cornerRadius = 12
        gameCard.backgroundColor = UIColor(hex: "F0FFDB")
    }

    // 💡 Configuration method for dynamic content
    func configure(with item: GameItem) {
        gameTitle.text = item.title.uppercased()
        gameImage.image = UIImage(named: item.imageAsset)
        // If your asset is an SF Symbol, use:
        // gameImage.image = UIImage(systemName: item.imageAsset)
    }

}
