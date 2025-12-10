// QuickGamesCollectionViewCell.swift

import UIKit

class QuickGamesCollectionViewCell: UICollectionViewCell {

    // Card 1 Outlets (Word Scramble)
    @IBOutlet weak var gameCard: UIView!
    // 💡 NEW: Connect this to the Image View (ID: e1L-HQ-Fdr) in the first card (e0S-fd-RpR)
    @IBOutlet weak var gameImage1: UIImageView!
    // 💡 NEW: Connect this to the Label (ID: Ukz-91-tdL) in the first card (e0S-fd-RpR)
    @IBOutlet weak var gameTitle1: UILabel!
    
    // Card 2 Outlets (Connections)
    @IBOutlet weak var gameCard2: UIView!
    // 💡 NEW: Connect this to the Image View (ID: 7U0-Lq-hUz) in the second card (go1-Jg-IlQ)
    @IBOutlet weak var gameImage2: UIImageView!
    // 💡 NEW: Connect this to the Label (ID: Mcb-Xl-7Nu) in the second card (go1-Jg-IlQ)
    @IBOutlet weak var gameTitle2: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        gameCard.layer.cornerRadius = 12
        gameCard.backgroundColor = UIColor(hex: "F0FFDB")
        gameCard2.layer.cornerRadius = 12
        // Set the background color for gameCard2 (currently set to system blue/cyan in XIB)
        gameCard2.backgroundColor = UIColor(hex: "91C1EF",alpha: 0.25)
    }

    // 💡 Configuration method for dynamic content for TWO items
    func configure(with item1: GameItem, and item2: GameItem) {
        
        // --- Configure Card 1 ---
        gameTitle1.text = item1.title.uppercased()
        
        if item1.imageAsset.contains(" ") == false && UIImage(systemName: item1.imageAsset) != nil {
            gameImage1.image = UIImage(systemName: item1.imageAsset)
        } else {
            gameImage1.image = UIImage(named: item1.imageAsset)
        }

        // --- Configure Card 2 ---
        gameTitle2.text = item2.title.uppercased()

        if item2.imageAsset.contains(" ") == false && UIImage(systemName: item2.imageAsset) != nil {
            gameImage2.image = UIImage(systemName: item2.imageAsset)
        } else {
            gameImage2.image = UIImage(named: item2.imageAsset)
        }
    }
}
