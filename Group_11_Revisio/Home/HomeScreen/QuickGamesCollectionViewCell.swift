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
    
    private func configureStyle() {
                [gameCard, gameCard2].forEach { card in
                    card?.layer.cornerRadius = 24
                    card?.layer.cornerCurve = .continuous
                    card?.isUserInteractionEnabled = true
                }
                
                let wordFillTheme = UIColor { trait in
                    trait.userInterfaceStyle == .dark
                    ? UIColor(red: 15/255, green: 23/255, blue: 36/255, alpha: 1.0)
                    : UIColor(red: 230/255, green: 242/255, blue: 255/255, alpha: 1.0)
                }
                
                let connectionsTheme = UIColor { trait in
                    trait.userInterfaceStyle == .dark
                    ? UIColor(red: 21/255, green: 18/255, blue: 33/255, alpha: 1.0)
                    : UIColor(red: 245/255, green: 235/255, blue: 255/255, alpha: 1.0)
                }
                
                // Apply the dynamic theme colors
                gameCard.backgroundColor = wordFillTheme
                gameCard2.backgroundColor = connectionsTheme
                
                gameTitle1.textColor = .label
                gameTitle2.textColor = .label
                
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
