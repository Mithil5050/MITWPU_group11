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
    private func configureStyle() {
        // Card Shape
        [gameCard, gameCard2].forEach { card in
            card?.layer.cornerRadius = 16
            card?.layer.cornerCurve = .continuous
            card?.isUserInteractionEnabled = true
        }
        
        // MARK: - 🔒 FORCE LIGHT MODE COLORS
        // We manually define the standard iOS Light Mode RGB values.
        // This prevents the system from swapping them to "Dark Mode Green/Blue".
        
        // Light Mode System Green: #34C759 (R: 52, G: 199, B: 89)
        let fixedLightGreen = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1.0)
        
        // Light Mode System Blue: #007AFF (R: 0, G: 122, B: 255)
        let fixedLightBlue = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0)
        
        // Apply with low opacity for the pastel look
        gameCard.backgroundColor = fixedLightGreen.withAlphaComponent(0.12)
        gameCard2.backgroundColor = fixedLightBlue.withAlphaComponent(0.12)
        
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
