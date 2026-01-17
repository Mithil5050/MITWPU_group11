import UIKit

class QuickGamesCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    static let reuseIdentifier = "QuickGamesCollectionViewCell"
    weak var delegate: QuickGamesCellDelegate?
    
    // MARK: - IBOutlets
    @IBOutlet weak var gameCard: UIView!
    @IBOutlet weak var gameImage1: UIImageView!
    @IBOutlet weak var gameTitle1: UILabel!
    
    @IBOutlet weak var gameCard2: UIView!
    @IBOutlet weak var gameImage2: UIImageView!
    @IBOutlet weak var gameTitle2: UILabel!
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        configureStyle()
        setupGestureRecognizers()
        gameImage1.layer.cornerRadius = 16
        gameImage2.layer.cornerRadius = 16
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        gameTitle1.text = nil
        gameTitle2.text = nil
        gameImage1.image = nil
        gameImage2.image = nil
    }
    
    // MARK: - UI Setup
    // MARK: - UI Setup
        private func configureStyle() {
            // Card Shape
            [gameCard, gameCard2].forEach { card in
                card?.layer.cornerRadius = 24 // Updated to match the smooth 24pt radius in the image
                card?.layer.cornerCurve = .continuous
                card?.isUserInteractionEnabled = true
            }
            
            // MARK: - 🎨 DARK MODE THEME COLORS
            // These colors match the deep background tones of the 3D assets provided.
            
            // WordFill: "Deep Azure" (#0F1724)
            // RGB: 15, 23, 36
            let wordFillTheme = UIColor(red: 15/255, green: 23/255, blue: 36/255, alpha: 1.0)
            
            // Connections: "Midnight Violet" (#151221)
            // RGB: 21, 18, 33
            let connectionsTheme = UIColor(red: 21/255, green: 18/255, blue: 33/255, alpha: 1.0)
            
            // Apply the solid theme colors
            gameCard.backgroundColor = wordFillTheme
            gameCard2.backgroundColor = connectionsTheme
            
            // Content Mode
            gameImage1.contentMode = .scaleAspectFit
            gameImage2.contentMode = .scaleAspectFit
        }
    
    private func setupGestureRecognizers() {
        let wordFillTap = UITapGestureRecognizer(target: self, action: #selector(handleWordFillTap))
        gameCard.addGestureRecognizer(wordFillTap)
        
        let connectionsTap = UITapGestureRecognizer(target: self, action: #selector(handleConnectionsTap))
        gameCard2.addGestureRecognizer(connectionsTap)
    }
    
    // MARK: - Actions
    @objc private func handleWordFillTap() {
        delegate?.didSelectQuickGame(gameTitle: "Word Fill")
    }
    
    @objc private func handleConnectionsTap() {
        delegate?.didSelectQuickGame(gameTitle: "Connections")
    }
    
    // MARK: - Configuration
    func configure(with item1: GameItem, and item2: GameItem) {
        gameTitle1.text = item1.title.uppercased()
        gameImage1.image = fetchImage(named: item1.imageAsset)
        
        gameTitle2.text = item2.title.uppercased()
        gameImage2.image = fetchImage(named: item2.imageAsset)
    }
    
    private func fetchImage(named name: String) -> UIImage? {
        if let symbolImage = UIImage(systemName: name) {
            return symbolImage
        }
        return UIImage(named: name)
    }
}
