import UIKit

// MARK: - AI Models
struct AIConnectionsResponse: Codable {
    struct AICategory: Codable {
        let title: String
        let words: [String]
    }
    let categories: [AICategory]
}

class ConnectionsViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - Properties
    var currentTopic: Topic? // Passed from Launch Screen

    private var categories: [CategoryModel] = []
    private var words: [WordModel] = []

    private var didWin: Bool = false
    private var gameStartTime: Date?
    private var mistakesRemaining: Int = 4 {
        didSet { updateMistakesLabel() }
    }

    // Loading UI
    private lazy var loadingOverlayView = GameLoadingOverlayView(
        title: "Crafting your Connections from \(currentTopic?.name ?? "General Knowledge")...",
        subtitle: "AI is grouping your categories"
    )

    // MARK: - UI Elements
    private let mistakesLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let controlsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var shuffleButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Shuffle"
        let action = UIAction { [weak self] _ in self?.handleShuffle() }
        return UIButton(configuration: config, primaryAction: action)
    }()

    private lazy var deselectButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Deselect All"
        let action = UIAction { [weak self] _ in self?.handleDeselect() }
        return UIButton(configuration: config, primaryAction: action)
    }()

    private lazy var submitButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Submit"
        let action = UIAction { [weak self] _ in self?.handleSubmit() }
        return UIButton(configuration: config, primaryAction: action)
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        installQuitConfirmation() // ✅ Guard against accidental exits

        if let topicName = currentTopic?.name {
            self.title = "Connections: \(topicName)"
        } else {
            self.title = "Connections"
        }

        view.backgroundColor = .systemBackground

        setupCollectionView()
        setupLayout()
        setupLoadingOverlay()

        updateMistakesLabel()
        updateSubmitButtonState()

        // Start generating!
        generateConnectionsGame()
    }

    // MARK: - AI GENERATION
    private func setupLoadingOverlay() {
        loadingOverlayView.show(in: view)
    }

    private func generateConnectionsGame() {
        Task {
            let contentBody = currentTopic?.largeContentBody ?? currentTopic?.notesContent ?? currentTopic?.cheatsheetContent ?? ""
            let safeContent = String(contentBody.prefix(15000))

            let prompt = """
            Create a "Connections" word puzzle game based on the following study material.
            You must create EXACTLY 4 categories.
            Each category MUST have a short, descriptive title.
            Each category MUST contain EXACTLY 4 words that belong to that category.
            The words should be single words or very short phrases (max 2 words).

            STRICTLY use this EXACT JSON format:
            {
              "categories": [
                {
                  "title": "DATA STRUCTURES",
                  "words": ["Stack", "Queue", "Tree", "Array"]
                }
              ]
            }
            Make sure there are exactly 4 categories in the array!

            STUDY MATERIAL:
            \(safeContent.isEmpty ? "General educational facts and trivia." : safeContent)
            """

            do {
                let jsonResponse = try await AIContentManager.shared.generateContent(
                    topic: prompt,
                    type: "Connections",
                    count: 1, // Doesn't matter, prompt dictates 4
                    difficulty: "Medium"
                )

                let cleanJSON = cleanJSONText(jsonResponse)
                guard let data = cleanJSON.data(using: .utf8) else { throw URLError(.cannotDecodeContentData) }

                let decoder = JSONDecoder()
                let result = try decoder.decode(AIConnectionsResponse.self, from: data)

                // Colors to assign
                let colors: [UIColor] = [.systemPurple, .systemGreen, .systemYellow, .systemBlue]

                var newCategories: [CategoryModel] = []
                for (index, aiCat) in result.categories.prefix(4).enumerated() {
                    let cat = CategoryModel(
                        id: index,
                        title: aiCat.title.uppercased(),
                        words: Array(aiCat.words.prefix(4)),
                        color: colors[index % colors.count]
                    )
                    newCategories.append(cat)
                }

                DispatchQueue.main.async {
                    self.categories = newCategories
                    self.words = WordModel.generateWords(from: self.categories)
                    self.hideLoadingAndStartGame()
                }

            } catch {
                print("⚠️ AI Connections Failed: \(error.localizedDescription). Using fallback.")
                DispatchQueue.main.async {
                    self.categories = CategoryModel.fallbackCategories
                    self.words = WordModel.generateWords(from: self.categories)
                    self.hideLoadingAndStartGame()
                }
            }
        }
    }

    private func cleanJSONText(_ json: String) -> String {
        var clean = json
        if clean.contains("```json") { clean = clean.replacingOccurrences(of: "```json", with: "") }
        clean = clean.replacingOccurrences(of: "```", with: "")
        if let startIndex = clean.firstIndex(of: "{") { clean = String(clean[startIndex...]) }
        if let endIndex = clean.lastIndex(of: "}") { clean = String(clean[...endIndex]) }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func hideLoadingAndStartGame() {
        gameStartTime = Date()
        loadingOverlayView.hide {
            self.collectionView.reloadData()
        }
    }

    // MARK: - UI Setup
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(WordCell.self, forCellWithReuseIdentifier: "WordCell")

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.setCollectionViewLayout(createGridLayout(), animated: false)
    }

    private func setupLayout() {
        view.addSubview(mistakesLabel)

        controlsStackView.addArrangedSubview(shuffleButton)
        controlsStackView.addArrangedSubview(deselectButton)
        controlsStackView.addArrangedSubview(submitButton)
        view.addSubview(controlsStackView)

        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            controlsStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            controlsStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            controlsStackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -8),
            controlsStackView.heightAnchor.constraint(equalToConstant: 48),

            mistakesLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            mistakesLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            mistakesLabel.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor, constant: -8),

            collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: mistakesLabel.topAnchor, constant: -8)
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

    // MARK: - Actions
    private func handleShuffle() {
        words.shuffle()
        collectionView.reloadData()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func handleDeselect() {
        for i in words.indices { words[i].isSelected = false }
        collectionView.reloadData()
        updateSubmitButtonState()
    }

    private func handleSubmit() {
        let selectedWords = words.filter { $0.isSelected }
        guard selectedWords.count == 4 else { return }

        let firstCategoryID = selectedWords.first?.categoryID
        let isCorrect = selectedWords.allSatisfy { $0.categoryID == firstCategoryID }

        if isCorrect, let categoryID = firstCategoryID {
            handleSuccess(for: categoryID)
        } else {
            handleMistake()
        }

        updateSubmitButtonState()
    }

    private func handleSuccess(for categoryID: Int) {
        guard let category = self.categories.first(where: { $0.id == categoryID }) else { return }

        for i in words.indices where words[i].isSelected {
            words[i].isGuessed = true
            words[i].isSelected = false
        }

        showAlert(title: "Correct!", message: "Group: \(category.title)", color: category.color)
        collectionView.reloadData()
        checkGameCompletion()
    }

    private func handleMistake() {
        mistakesRemaining -= 1
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        if mistakesRemaining > 0 {
            showAlert(title: "Incorrect Group", message: "Try again!", color: .systemRed)
        }
    }

    private func updateMistakesLabel() {
        let bullets = String(repeating: "●", count: mistakesRemaining)
        mistakesLabel.text = "Mistakes Remaining: \(bullets)"

        if mistakesRemaining <= 0 {
            finishGame(won: false)
        }
    }

    private func checkGameCompletion() {
        let solvedCount = words.filter { $0.isGuessed }.count
        if solvedCount == 16 {
            finishGame(won: true)
        }
    }

    private func finishGame(won: Bool) {

        didWin = won
        collectionView.isUserInteractionEnabled = false

        if won {
                // ✅ 1. Update Badge Stat
                ProgressDataManager.shared.totalConnectionsWon += 1

                // ✅ 2. Award XP and trigger UI refresh
                Task {
                    await RevisioManager.shared.earnXP(amount: 20, reason: "Beat Connections")
                }
            }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.performSegue(withIdentifier: "ShowConnectionsResults", sender: nil)
        }
    }

    private func updateSubmitButtonState() {
        let selectedCount = words.filter { $0.isSelected }.count
        submitButton.isEnabled = selectedCount == 4
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowConnectionsResults",
           let destVC = segue.destination as? ConnectionsResultsViewController {

            // ✅ We pass the dynamic AI categories to the results screen
            destVC.categories = self.categories
            destVC.resultTitle = didWin ? "Great Job!" : "Better luck next time!"
            // Pass actual elapsed time for accurate progress logging
            if let start = gameStartTime {
                destVC.elapsedMinutes = Date().timeIntervalSince(start) / 60.0
            }
        }
    }

    private func showAlert(title: String, message: String, color: UIColor? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Collection View Methods
extension ConnectionsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WordCell", for: indexPath) as? WordCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: words[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !words[indexPath.item].isGuessed else { return }

        words[indexPath.item].isSelected.toggle()

        let selectedCount = words.filter { $0.isSelected }.count
        if selectedCount > 4 {
            words[indexPath.item].isSelected = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        collectionView.reloadItems(at: [indexPath])
        updateSubmitButtonState()
    }
}
