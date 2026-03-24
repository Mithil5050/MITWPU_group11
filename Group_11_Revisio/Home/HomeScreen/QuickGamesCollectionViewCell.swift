import UIKit

class QuickGamesCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    static let reuseIdentifier = "QuickGamesCollectionViewCell"
    weak var delegate: QuickGamesCellDelegate?
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scrollView)
        
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with items: [GameItem]) {
        // Clear old items
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let themes: [(light: UIColor, dark: UIColor)] = [
            (UIColor(red: 230/255, green: 242/255, blue: 255/255, alpha: 1.0),
             UIColor(red: 15/255, green: 23/255, blue: 36/255, alpha: 1.0)),
            
            (UIColor(red: 245/255, green: 235/255, blue: 255/255, alpha: 1.0),
             UIColor(red: 21/255, green: 18/255, blue: 33/255, alpha: 1.0)),
            
            (UIColor(red: 235/255, green: 245/255, blue: 255/255, alpha: 1.0),
             UIColor(red: 20/255, green: 30/255, blue: 35/255, alpha: 1.0))
        ]
        
        for (index, item) in items.enumerated() {
            let cardView = UIView()
            cardView.layer.cornerRadius = 24
            cardView.layer.cornerCurve = .continuous
            cardView.isUserInteractionEnabled = true
            cardView.translatesAutoresizingMaskIntoConstraints = false
            
            let theme = themes[index % themes.count]
            cardView.backgroundColor = UIColor { trait in
                trait.userInterfaceStyle == .dark ? theme.dark : theme.light
            }
            
            let imageView = UIImageView(image: fetchImage(named: item.imageAsset))
            imageView.contentMode = .scaleAspectFit
            imageView.layer.cornerRadius = 16
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            cardView.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                cardView.widthAnchor.constraint(equalToConstant: 160),
                
                imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
                imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
                imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
                imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
            ])
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleCardTap(_:)))
            cardView.addGestureRecognizer(tap)
            cardView.tag = index
            
            stackView.addArrangedSubview(cardView)
        }
    }
    
    private var cachedItems: [GameItem] = []
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cachedItems.removeAll()
    }
    
    @objc private func handleCardTap(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        
        // Items match tag
        let titles = ["Word Fill", "Connections", "Diagram Dash"]
        if view.tag < titles.count {
            delegate?.didSelectQuickGame(gameTitle: titles[view.tag])
        }
    }
    
    private func fetchImage(named name: String) -> UIImage? {
        if let symbolImage = UIImage(systemName: name) {
            return symbolImage
        }
        return UIImage(named: name)
    }
}
