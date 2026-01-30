import UIKit

// Protocol for HomeViewController
protocol ContinueLearningCellDelegate: AnyObject {
    func didSelectLearningItem(_ item: ContentItem)
}

class ContinueLearningCollectionViewCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Deleted: quizlogo, LogoView, ViewShow (No longer needed)
    
    var learningItems: [ContentItem] = []
    weak var delegate: ContinueLearningCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false // Height is controlled by CollectionView
        
        // Register Cell
        let nib = UINib(nibName: "LearningTaskCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "LearningTaskCell")
    }
    
    func configure(with items: [ContentItem]) {
        self.learningItems = items
        self.tableView.reloadData()
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return learningItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LearningTaskCell", for: indexPath) as? LearningTaskCell else {
            return UITableViewCell()
        }
        
        // In tableView(_ cellForRowAt:) ...
            
            let item = learningItems[indexPath.row]
            
            // Determine type
            var taskType: TaskType = .other
            if item.itemType == "Quiz" { taskType = .quiz }
            else if item.itemType == "Topic" || item.itemType == "Notes" { taskType = .notes }
            else if item.itemType == "Flashcard" { taskType = .flashcard } // 🆕 Map logic
            
            let taskViewModel = LearningTask(
                title: item.title,
                subtitle: nil,
                remainingModules: 0,
                type: taskType
            
        )
        
        cell.configure(with: taskViewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75 // Matches the rowHeight in HomeViewController
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedItem = learningItems[indexPath.row]
        delegate?.didSelectLearningItem(selectedItem)
    }
}
