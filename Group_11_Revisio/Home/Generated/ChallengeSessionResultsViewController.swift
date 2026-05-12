import UIKit

class ChallengeSessionResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UI Components
    private let resultImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.image = UIImage(named: "GoodMarks")
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = "Congratulations!"
        l.font = .systemFont(ofSize: 32, weight: .bold)
        l.textAlignment = .center
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .medium)
        l.textAlignment = .center
        l.textColor = .lightGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // Performance Insights Card
    private let insightsCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        v.layer.cornerRadius = 24
        v.layer.masksToBounds = true
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let insightsTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Performance Insights"
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let accuracyLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .lightGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let studyTimeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .lightGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // Summary Navigation Option
    private let summaryContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let summaryLabel: UILabel = {
        let l = UILabel()
        l.text = "View Session Summary"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let summaryChevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)))
        iv.tintColor = .systemGray
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let challengeButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = .systemIndigo
        b.setTitle("Start Challenge", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        b.layer.cornerRadius = 14
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()
    
    private let exitButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        b.setTitle("Save & Exit", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        b.layer.cornerRadius = 14
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // Properties
    var knownCount: Int = 0
    var totalCount: Int = 0
    var isChallengeResult: Bool = false
    var flashcardSummary: [(term: String, definition: String)] = []
    var sessionDuration: TimeInterval = 300 // Default 5 mins if not passed
    
    var onSaveAndExit: (() -> Void)?
    var onChallengeMode: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        updateData()
    }
    
    private func updateData() {
        scoreLabel.text = "You mastered all \(knownCount) cards!"
        challengeButton.isHidden = isChallengeResult
        
        let accuracy = totalCount > 0 ? Int((Double(knownCount) / Double(totalCount)) * 100) : 0
        accuracyLabel.text = "• Accuracy: \(accuracy)%"
        
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60
        if minutes > 0 {
            studyTimeLabel.text = "• Study Time: \(minutes)m \(seconds)s"
        } else {
            studyTimeLabel.text = "• Study Time: \(seconds)s"
        }
        
        if isChallengeResult {
            insightsTitleLabel.text = "Challenge Summary"
        }
    }
    
    private func setupUI() {
        view.addSubview(resultImageView)
        view.addSubview(headerLabel)
        view.addSubview(scoreLabel)
        view.addSubview(insightsCard)
        
        insightsCard.addSubview(insightsTitleLabel)
        insightsCard.addSubview(accuracyLabel)
        insightsCard.addSubview(studyTimeLabel)
        insightsCard.addSubview(summaryContainer)
        
        summaryContainer.addSubview(summaryLabel)
        summaryContainer.addSubview(summaryChevron)
        
        view.addSubview(challengeButton)
        view.addSubview(exitButton)
        
        // MARK: - Constraints
        NSLayoutConstraint.activate([
            // Hero Image Section
            resultImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            resultImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultImageView.heightAnchor.constraint(equalToConstant: 320),
            
            // Congratulations
            headerLabel.topAnchor.constraint(equalTo: resultImageView.bottomAnchor, constant: 12),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Subtitle
            scoreLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 4),
            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Insights Card
            insightsCard.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 20),
            insightsCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            insightsCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Inside Insights Card
            insightsTitleLabel.topAnchor.constraint(equalTo: insightsCard.topAnchor, constant: 20),
            insightsTitleLabel.leadingAnchor.constraint(equalTo: insightsCard.leadingAnchor, constant: 20),
            
            accuracyLabel.topAnchor.constraint(equalTo: insightsTitleLabel.bottomAnchor, constant: 12),
            accuracyLabel.leadingAnchor.constraint(equalTo: insightsTitleLabel.leadingAnchor, constant: 12),
            
            studyTimeLabel.topAnchor.constraint(equalTo: accuracyLabel.bottomAnchor, constant: 6),
            studyTimeLabel.leadingAnchor.constraint(equalTo: accuracyLabel.leadingAnchor),
            
            // Summary Container Row
            summaryContainer.topAnchor.constraint(equalTo: studyTimeLabel.bottomAnchor, constant: 20),
            summaryContainer.leadingAnchor.constraint(equalTo: insightsCard.leadingAnchor, constant: 16),
            summaryContainer.trailingAnchor.constraint(equalTo: insightsCard.trailingAnchor, constant: -16),
            summaryContainer.heightAnchor.constraint(equalToConstant: 54),
            summaryContainer.bottomAnchor.constraint(equalTo: insightsCard.bottomAnchor, constant: -16),
            
            summaryLabel.centerYAnchor.constraint(equalTo: summaryContainer.centerYAnchor),
            summaryLabel.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor, constant: 16),
            
            summaryChevron.centerYAnchor.constraint(equalTo: summaryContainer.centerYAnchor),
            summaryChevron.trailingAnchor.constraint(equalTo: summaryContainer.trailingAnchor, constant: -16),
            
            // Buttons
            exitButton.leadingAnchor.constraint(equalTo: insightsCard.leadingAnchor),
            exitButton.trailingAnchor.constraint(equalTo: insightsCard.trailingAnchor),
            exitButton.heightAnchor.constraint(equalToConstant: 54)
        ])
        
        if isChallengeResult {
            NSLayoutConstraint.activate([
                exitButton.topAnchor.constraint(equalTo: insightsCard.bottomAnchor, constant: 24)
            ])
        } else {
            NSLayoutConstraint.activate([
                challengeButton.topAnchor.constraint(equalTo: insightsCard.bottomAnchor, constant: 20),
                challengeButton.leadingAnchor.constraint(equalTo: insightsCard.leadingAnchor),
                challengeButton.trailingAnchor.constraint(equalTo: insightsCard.trailingAnchor),
                challengeButton.heightAnchor.constraint(equalToConstant: 54),
                
                exitButton.topAnchor.constraint(equalTo: challengeButton.bottomAnchor, constant: 12)
            ])
        }
        
        challengeButton.addTarget(self, action: #selector(challengeTapped), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(showSummary))
        summaryContainer.addGestureRecognizer(tap)
        summaryContainer.isUserInteractionEnabled = true
    }
    
    @objc private func showSummary() {
        let summaryVC = FlashcardSummaryViewController()
        summaryVC.summaryItems = flashcardSummary
        navigationController?.pushViewController(summaryVC, animated: true)
    }
    
    @objc private func challengeTapped() {
        dismiss(animated: true) { self.onChallengeMode?() }
    }
    
    @objc private func exitTapped() {
        dismiss(animated: true) { self.onSaveAndExit?() }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 0 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return UITableViewCell() }
}
