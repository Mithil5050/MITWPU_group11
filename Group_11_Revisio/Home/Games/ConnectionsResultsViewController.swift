import UIKit

class ConnectionsResultsViewController: UIViewController {

    // MARK: - Properties
    var categories: [CategoryModel] = CategoryModel.allCategories
    
    // Property to change the title text (e.g., "Great Job!" or "Better luck next time!")
    var resultTitle: String = "Great Job!"
    
    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = resultTitle
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let homeButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Back to Home"
        config.baseBackgroundColor = .label
        config.baseForegroundColor = .systemBackground
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        btn.configuration = config
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Ensure label reflects the property
        titleLabel.text = resultTitle
        
        setupLayout()
        buildCategoryCards()
        
        homeButton.addTarget(self, action: #selector(homeTapped), for: .touchUpInside)
    }
    
    // MARK: - UI Setup
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(stackView)
        view.addSubview(homeButton)
        
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Stack View (Holds the 4 cards)
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Home Button
            homeButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -40),
            homeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            homeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func buildCategoryCards() {
        for category in categories {
            let cardView = createCard(for: category)
            stackView.addArrangedSubview(cardView)
            cardView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        }
    }
    
    private func createCard(for category: CategoryModel) -> UIView {
        let container = UIView()
        
        // ✅ NEW: Apply Pastel Colors based on the original category color
        var pastelColor = category.color // Fallback
        
        // Check using description or properties if available,
        // otherwise assuming standard order or system color equality.
        if category.color == .systemPurple {
            pastelColor = UIColor(red: 219/255, green: 196/255, blue: 236/255, alpha: 1.0) // Lavender
        } else if category.color == .systemGreen {
            pastelColor = UIColor(red: 186/255, green: 218/255, blue: 145/255, alpha: 1.0) // Soft Green
        } else if category.color == .systemYellow {
            pastelColor = UIColor(red: 250/255, green: 236/255, blue: 135/255, alpha: 1.0) // Creamy Yellow
        } else if category.color == .systemBlue {
            pastelColor = UIColor(red: 184/255, green: 207/255, blue: 245/255, alpha: 1.0) // Pastel Blue
        } else {
            // If custom colors are used, lighten them
            pastelColor = category.color.withAlphaComponent(0.4)
        }
        
        container.backgroundColor = pastelColor
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let catTitle = UILabel()
        catTitle.text = category.title.uppercased()
        catTitle.font = UIFont.systemFont(ofSize: 16, weight: .black)
        // ✅ NEW: Black text for contrast on pastel
        catTitle.textColor = .black
        catTitle.textAlignment = .center
        catTitle.translatesAutoresizingMaskIntoConstraints = false
        
        let wordsLabel = UILabel()
        wordsLabel.text = category.words.joined(separator: ", ")
        wordsLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        // ✅ NEW: Black text for contrast on pastel
        wordsLabel.textColor = .black
        wordsLabel.textAlignment = .center
        wordsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(catTitle)
        container.addSubview(wordsLabel)
        
        NSLayoutConstraint.activate([
            catTitle.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            catTitle.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -10),
            wordsLabel.topAnchor.constraint(equalTo: catTitle.bottomAnchor, constant: 4),
            wordsLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            wordsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 8),
            wordsLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -8)
        ])
        
        return container
    }
    
    @objc private func homeTapped() {
        navigationController?.popToRootViewController(animated: true)
    }
}
