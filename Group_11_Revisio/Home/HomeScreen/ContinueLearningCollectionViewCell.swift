import UIKit

protocol ContinueLearningCellDelegate: AnyObject {
    func didSelectLearningItem(_ item: ContentItem)
}

class ContinueLearningCollectionViewCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Empty State Label
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Material to continue learning"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    var learningItems: [ContentItem] = []
    weak var delegate: ContinueLearningCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupEmptyLabel()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        
        let nib = UINib(nibName: "LearningTaskCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "LearningTaskCell")
    }
    
    private func setupEmptyLabel() {
        contentView.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with items: [ContentItem]) {
        self.learningItems = items
        
        if items.isEmpty {
            tableView.isHidden = true
            emptyLabel.isHidden = false
        } else {
            tableView.isHidden = false
            emptyLabel.isHidden = true
            self.tableView.reloadData()
        }
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return learningItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LearningTaskCell", for: indexPath) as? LearningTaskCell else {
            return UITableViewCell()
        }
        
        let item = learningItems[indexPath.row]
        let typeLower = item.itemType.lowercased()
        
        // ✅ STRICT & ROBUST MAPPING
        var taskType: TaskType = .other
        
        if typeLower.contains("quiz") {
            taskType = .quiz
        } else if typeLower.contains("flashcard") {
            taskType = .flashcard
        } else if typeLower.contains("cheatsheet") {
            taskType = .cheatsheet
        } else if typeLower.contains("note") || typeLower.contains("topic") {
            taskType = .notes
        }
        
        let taskViewModel = LearningTask(
            title: item.title,
            subtitle: nil,
            remainingModules: (taskType == .quiz) ? 10 : 0,
            type: taskType
        )
        
        cell.configure(with: taskViewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedItem = learningItems[indexPath.row]
        delegate?.didSelectLearningItem(selectedItem)
    }
}
