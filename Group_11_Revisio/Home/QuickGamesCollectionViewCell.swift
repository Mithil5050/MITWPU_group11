import UIKit

class QuickGamesCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    static let reuseIdentifier = "QuickGamesCollectionViewCell"
    weak var delegate: QuickGamesCellDelegate?
    
    // MARK: - IBOutlets
    // Card 1: Word Fill
    @IBOutlet weak var gameCard: UIView!
    @IBOutlet weak var gameImage1: UIImageView!
    @IBOutlet weak var gameTitle1: UILabel!
    
    // Card 2: Connections
    @IBOutlet weak var gameCard2: UIView!
    @IBOutlet weak var gameImage2: UIImageView!
    @IBOutlet weak var gameTitle2: UILabel!
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        configureStyle()
        setupGestureRecognizers()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset cell state for recycled use
        gameTitle1.text = nil
        gameTitle2.text = nil
        gameImage1.image = nil
        gameImage2.image = nil
    }
    
    // MARK: - UI Setup
    private func configureStyle() {
        // Applying iOS 26 High-Fidelity Design Patterns
        [gameCard, gameCard2].forEach { card in
            card?.layer.cornerRadius = 16
            card?.layer.cornerCurve = .continuous // Smooth Apple-style corners
            card?.isUserInteractionEnabled = true
        }
        
        // Semantic background colors for Light/Dark mode compatibility
        gameCard.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        gameCard2.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        
        // Ensure images use a consistent content mode
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
    /// Populates the dual-card cell with game data.
    func configure(with item1: GameItem, and item2: GameItem) {
        // Configure Card 1
        gameTitle1.text = item1.title.uppercased()
        gameImage1.image = fetchImage(named: item1.imageAsset)
        
        // Configure Card 2
        gameTitle2.text = item2.title.uppercased()
        gameImage2.image = fetchImage(named: item2.imageAsset)
    }
    
    private func fetchImage(named name: String) -> UIImage? {
        // Prioritize SF Symbols, fallback to Asset Catalog
        if let symbolImage = UIImage(systemName: name) {
            return symbolImage
        }
        return UIImage(named: name)
    }
}
