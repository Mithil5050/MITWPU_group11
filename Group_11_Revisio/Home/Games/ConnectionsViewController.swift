//
//  ConnectionsViewController.swift
//
//  Final code with Win/Loss Navigation logic
//

import UIKit

// MARK: - Connections View Controller
class ConnectionsViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Programmatic UI Elements
    private let mistakesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let shuffleButton = UIButton(configuration: .plain())
    private let deselectButton = UIButton(configuration: .plain())
    private let submitButton = UIButton(configuration: .filled())
    
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
    
    // ✅ NEW: Track if user won or lost to determine the result message
    private var didWin: Bool = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupUI()
        setupProgrammaticLayout()
        updateMistakesLabel()
        updateSubmitButtonState()
    }

    // MARK: - Setup
    private func setupUI() {
        self.title = "Connections"

        shuffleButton.setTitle("Shuffle", for: .normal)
        deselectButton.setTitle("Deselect All", for: .normal)
        submitButton.setTitle("Submit", for: .normal)
        
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

    // MARK: - Layout
    private func setupProgrammaticLayout() {
        view.addSubview(mistakesLabel)
        controlsStackView.addArrangedSubview(shuffleButton)
        controlsStackView.addArrangedSubview(deselectButton)
        controlsStackView.addArrangedSubview(submitButton)
        view.addSubview(controlsStackView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        mistakesLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false

        let safeArea = view.safeAreaLayoutGuide
        let padding: CGFloat = 16.0
        let controlsHeight: CGFloat = 48.0
        let tightSpacing: CGFloat = 8.0
        let minorSpacing: CGFloat = 4.0

        NSLayoutConstraint.activate([
            controlsStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: padding),
            controlsStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -padding),
            controlsStackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -tightSpacing),
            controlsStackView.heightAnchor.constraint(equalToConstant: controlsHeight),
            
            mistakesLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: padding),
            mistakesLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -padding),
            mistakesLabel.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor, constant: -minorSpacing),

            collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: mistakesLabel.topAnchor, constant: -tightSpacing)
        ])
    }

    private func createGridLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.25), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(80))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(8)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Game Logic
    private func updateMistakesLabel() {
        let bullets = String(repeating: "●", count: mistakesRemaining)
        mistakesLabel.text = "Mistakes Remaining: \(bullets)"
        
        // ✅ NEW: Navigate to Results on 0 mistakes
        if mistakesRemaining <= 0 {
            didWin = false // User Lost
            collectionView.isUserInteractionEnabled = false
            
            // Show the result screen after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.performSegue(withIdentifier: "ShowConnectionsResults", sender: nil)
            }
        }
    }

    private func updateSubmitButtonState() {
        let selectedCount = words.filter { $0.isSelected }.count
        submitButton.isEnabled = selectedCount == 4
    }

    private func checkSubmittedWords() {
        let selectedWords = words.filter { $0.isSelected }
        guard selectedWords.count == 4 else { return }

        let firstCategoryID = selectedWords.first?.categoryID
        let isCorrect = selectedWords.allSatisfy { $0.categoryID == firstCategoryID }

        if isCorrect {
            let categoryTitle = CategoryModel.allCategories.first(where: { $0.id == firstCategoryID })?.title ?? "Unknown"
            
            for i in words.indices {
                if words[i].isSelected {
                    words[i].isGuessed = true
                    words[i].isSelected = false
                }
            }
            
            let successColor = CategoryModel.allCategories.first(where: { $0.id == firstCategoryID })?.color ?? .systemTeal
            showAlert(title: "Correct!", message: "Group: \(categoryTitle)", color: successColor)
            
            collectionView.reloadData()
            checkGameCompletion()
            
        } else {
            mistakesRemaining -= 1
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            // Only show "Try again" if they still have mistakes left
            if mistakesRemaining > 0 {
                showAlert(title: "Incorrect Group", message: "Try again!", color: .systemRed)
            }
        }
        
        updateSubmitButtonState()
    }
    
    private func checkGameCompletion() {
        let solvedCount = words.filter { $0.isGuessed }.count
        
        if solvedCount == 16 {
            didWin = true // User Won
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.performSegue(withIdentifier: "ShowConnectionsResults", sender: nil)
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowConnectionsResults" {
            if let destVC = segue.destination as? ConnectionsResultsViewController {
                destVC.categories = CategoryModel.allCategories
                
                // ✅ NEW: Set title based on win/loss status
                destVC.resultTitle = didWin ? "Great Job!" : "Better luck next time!"
            }
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
