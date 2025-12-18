//
//  ConnectionsViewController.swift
//
//  Final code using programmatic Auto Layout for controls.
//

import UIKit

// MARK: - Connections View Controller
class ConnectionsViewController: UIViewController {

    // MARK: - IBOutlets (ONLY the Collection View remains connected from Storyboard)
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Programmatic UI Elements
    // 1. Status Label
    private let mistakesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    // 2. Control Buttons
    private let shuffleButton = UIButton(configuration: .plain())
    private let deselectButton = UIButton(configuration: .plain())
    private let submitButton = UIButton(configuration: .filled())
    
    // 3. Stack View (Container for buttons)
    private let controlsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 8
        return stack
    }()
    
    // MARK: - Game State
    private var words: [WordModel] = WordModel.generateInitialWords()
    private var mistakesRemaining: Int = 4 {
        didSet {
            updateMistakesLabel()
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupUI()
        setupProgrammaticLayout() // Defines all Auto Layout constraints
        updateMistakesLabel()
        updateSubmitButtonState()
    }

    // MARK: - Setup
    private func setupUI() {
        self.title = "Connections"

        shuffleButton.setTitle("Shuffle", for: .normal)
        deselectButton.setTitle("Deselect All", for: .normal)
        submitButton.setTitle("Submit", for: .normal)
        
        // Assign Targets
        shuffleButton.addTarget(self, action: #selector(shuffleButtonTapped(_:)), for: .touchUpInside)
        deselectButton.addTarget(self, action: #selector(deselectButtonTapped(_:)), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitButtonTapped(_:)), for: .touchUpInside)
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(WordCell.self, forCellWithReuseIdentifier: "WordCell")
        let layout = createGridLayout()
        collectionView.setCollectionViewLayout(layout, animated: false)
    }

    // MARK: - Programmatic Auto Layout Implementation
    private func setupProgrammaticLayout() {
        
        // 1. Add elements to the view hierarchy
        view.addSubview(mistakesLabel)
        controlsStackView.addArrangedSubview(shuffleButton)
        controlsStackView.addArrangedSubview(deselectButton)
        controlsStackView.addArrangedSubview(submitButton)
        view.addSubview(controlsStackView)

        // Disable automatic translation to constraints for all controlled views
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        mistakesLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false

        let safeArea = view.safeAreaLayoutGuide
        let padding: CGFloat = 16.0
        let controlsHeight: CGFloat = 48.0
        
        // Constants for the tight spacing at the bottom
        let tightSpacing: CGFloat = 8.0 // Used for minimal spacing (8pt)
        let minorSpacing: CGFloat = 4.0 // Used for the tiny gap between status and controls

        // 2. Controls Stack View (Anchored very close to the bottom safe area)
        NSLayoutConstraint.activate([
            // Horizontal constraints
            controlsStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: padding),
            controlsStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -padding),
            
            // Vertical constraints (Tight anchor to the safe area bottom)
            controlsStackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -tightSpacing),
            controlsStackView.heightAnchor.constraint(equalToConstant: controlsHeight)
        ])
        
        // 3. Mistakes Label (Anchored immediately above the Stack View)
        NSLayoutConstraint.activate([
            // Horizontal constraints
            mistakesLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: padding),
            mistakesLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -padding),
            
            // Vertical constraints (Minimal spacing above the Stack View)
            mistakesLabel.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor, constant: -minorSpacing)
        ])

        // 4. Collection View (Fills the remaining space)
        NSLayoutConstraint.activate([
            // Horizontal constraints
            collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            
            // Vertical constraints (Top to Navigation Bar bottom, Bottom to Mistakes Label top with tight spacing)
            collectionView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: mistakesLabel.topAnchor, constant: -tightSpacing)
        ])
    }

    // MARK: - iOS 26 UICollectionView Layout
    private func createGridLayout() -> UICollectionViewLayout {
        // Item configuration (Cell is 1/4 the width of the group)
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.25), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // Group configuration (4 items across)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(80))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(8)
        
        // Section configuration
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Game Logic
    private func updateMistakesLabel() {
        let bullets = String(repeating: "●", count: mistakesRemaining)
        mistakesLabel.text = "Mistakes Remaining: \(bullets)"
        
        if mistakesRemaining <= 0 {
            showAlert(title: "Game Over", message: "You ran out of mistakes! Better luck next time.")
            collectionView.isUserInteractionEnabled = false
        }
    }

    private func updateSubmitButtonState() {
        let selectedCount = words.filter { $0.isSelected }.count
        submitButton.isEnabled = selectedCount == 4
    }

    private func checkSubmittedWords() {
        let selectedWords = words.filter { $0.isSelected }
        guard selectedWords.count == 4 else { return }

        // Check if all four words share the same categoryID
        let firstCategoryID = selectedWords.first?.categoryID
        let isCorrect = selectedWords.allSatisfy { $0.categoryID == firstCategoryID }

        if isCorrect {
            // SUCCESS: Found a category!
            let categoryTitle = CategoryModel.allCategories.first(where: { $0.id == firstCategoryID })?.title ?? "Unknown"
            
            // 1. Update the game model
            for i in words.indices {
                if words[i].isSelected {
                    words[i].isGuessed = true
                    words[i].isSelected = false
                }
            }
            
            // 2. Provide feedback
            let successColor = CategoryModel.allCategories.first(where: { $0.id == firstCategoryID })?.color ?? .systemTeal
            showAlert(title: "Correct!", message: "Group: \(categoryTitle)", color: successColor)
            
            // 3. Animate/Update the UI
            collectionView.reloadData()
            checkGameCompletion()
            
        } else {
            // FAILURE
            mistakesRemaining -= 1
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            showAlert(title: "Incorrect Group", message: "Try again!", color: .systemRed)
        }
        
        updateSubmitButtonState()
    }
    
    private func checkGameCompletion() {
        let solvedCount = words.filter { $0.isGuessed }.count
        if solvedCount == 16 {
            showAlert(title: "Congratulations!", message: "You solved all the connections!", color: .systemGreen)
            collectionView.isUserInteractionEnabled = false
        }
    }
    
    // MARK: - Alert Helper
    private func showAlert(title: String, message: String, color: UIColor? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - IBActions
    @objc func shuffleButtonTapped(_ sender: UIButton) {
        words.shuffle()
        collectionView.reloadData()
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    @objc func deselectButtonTapped(_ sender: UIButton) {
        for i in words.indices { words[i].isSelected = false }
        collectionView.reloadData()
        updateSubmitButtonState()
    }

    @objc func submitButtonTapped(_ sender: UIButton) {
        checkSubmittedWords()
    }
}

// MARK: - UICollectionViewDataSource
extension ConnectionsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Assuming WordCell.swift is defined
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WordCell", for: indexPath) as? WordCell else {
            return UICollectionViewCell()
        }
        let wordModel = words[indexPath.item]
        cell.configure(with: wordModel)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ConnectionsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if words[indexPath.item].isGuessed {
            return
        }
        
        words[indexPath.item].isSelected.toggle()
        
        let selectedCount = words.filter { $0.isSelected }.count
        if selectedCount > 4 {
            words[indexPath.item].isSelected = false
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        collectionView.reloadItems(at: [indexPath])
        updateSubmitButtonState()
    }
}
