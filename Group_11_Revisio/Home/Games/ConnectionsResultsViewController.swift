import UIKit

class ConnectionsResultsViewController: UIViewController {

    // MARK: - Properties
    var categories: [CategoryModel] = CategoryModel.allCategories
    var resultTitle: String = "Great Job!"
    
    // MARK: - UI Elements
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = resultTitle
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
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
    
    private lazy var homeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Back to Home"
        config.baseBackgroundColor = .label
        config.baseForegroundColor = .systemBackground
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        
        let action = UIAction { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        
        let btn = UIButton(configuration: config, primaryAction: action)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupLayout()
        buildCategoryCards()
    }
    
    // MARK: - Setup
    private func setupAppearance() {
        view.backgroundColor = .systemBackground
        titleLabel.text = resultTitle
    }
    
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(stackView)
        view.addSubview(homeButton)
        
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            homeButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -40),
            homeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            homeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func buildCategoryCards() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for category in categories {
            let cardView = createCard(for: category)
            stackView.addArrangedSubview(cardView)
            
            cardView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        }
    }
    
    private func createCard(for category: CategoryModel) -> UIView {
        let container = UIView()
        container.backgroundColor = getPastelColor(for: category.color)
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let catTitle = UILabel()
        catTitle.text = category.title.uppercased()
        catTitle.font = .systemFont(ofSize: 16, weight: .black)
        catTitle.textColor = .black
        catTitle.textAlignment = .center
        catTitle.translatesAutoresizingMaskIntoConstraints = false
        
        let wordsLabel = UILabel()
        wordsLabel.text = category.words.joined(separator: ", ")
        wordsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        wordsLabel.textColor = .black
        wordsLabel.textAlignment = .center
        wordsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(catTitle)
        container.addSubview(wordsLabel)
        
        NSLayoutConstraint.activate([
            catTitle.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            catTitle.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -10),
            
            wordsLabel.topAnchor.constraint(equalTo: catTitle.bottomAnchor, constant: 4),
            wordsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 8),
            wordsLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -8),
            wordsLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        
        return container
    }
    
    // MARK: - Helpers
    
    private func getPastelColor(for color: UIColor) -> UIColor {
        switch color {
        case .systemPurple:
            return UIColor(red: 219/255, green: 196/255, blue: 236/255, alpha: 1.0)
        case .systemGreen:
            return UIColor(red: 186/255, green: 218/255, blue: 145/255, alpha: 1.0)
        case .systemYellow:
            return UIColor(red: 250/255, green: 236/255, blue: 135/255, alpha: 1.0)
        case .systemBlue:
            return UIColor(red: 184/255, green: 207/255, blue: 245/255, alpha: 1.0)
        default:
            return color.withAlphaComponent(0.4)
        }
    }
}
