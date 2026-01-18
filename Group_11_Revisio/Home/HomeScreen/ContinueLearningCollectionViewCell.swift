import UIKit

// 1. Define the Protocol to talk to HomeViewController
protocol ContinueLearningCellDelegate: AnyObject {
    func didSelectLearningTask(_ task: PlanTask)
}

class ContinueLearningCollectionViewCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet var quizlogo: UIImageView!
    @IBOutlet var LogoView: UIView!
    @IBOutlet var ViewShow: UIView!
    
    var incompleteTasks: [PlanTask] = []
    
    // 2. Add the delegate property
    weak var delegate: ContinueLearningCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        
        // 1. Dynamic Background for the Card Container (ViewShow)
        // Light Mode: #F5F5F5, Dark Mode: System Dark Gray
        ViewShow.backgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .secondarySystemGroupedBackground
            } else {
                return UIColor(hex: "F5F5F5")
            }
        }
        ViewShow.layer.cornerRadius = 12
        
        // 2. Setup Mint Color for Logo (Works in both modes)
        let mintColor = UIColor(hex: "74DA9B")
        
        LogoView.backgroundColor = mintColor.withAlphaComponent(0.15)
        LogoView.layer.cornerRadius = 8
        
        quizlogo.tintColor = mintColor
        
        // CRITICAL: Keep this registry line to prevent crashes
        let nib = UINib(nibName: "LearningTaskCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "LearningTaskCell")
    }
    
    func configure(with tasks: [PlanTask]) {
        self.incompleteTasks = tasks
        self.tableView.reloadData()
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return incompleteTasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LearningTaskCell", for: indexPath) as? LearningTaskCell else {
            return UITableViewCell()
        }
        
        let planItem = incompleteTasks[indexPath.row]
        
        // ✅ FIX: Map the actual String type from JSON to the Enum
        var taskType: TaskType = .other
        
        // Check strings like "Notes", "Revision", "Quiz"
        if planItem.type.contains("Notes") || planItem.type.contains("Revision") {
            taskType = .notes
        } else if planItem.type.contains("Quiz") {
            taskType = .quiz
        } else if planItem.type.contains("Video") {
            taskType = .video
        }
        
        let task = LearningTask(
            title: planItem.title,
            subtitle: nil, // We let the cell generate the "modules remaining" text
            remainingModules: Int.random(in: 2...5), // Dummy count for UI demo
            type: taskType
        )
        
        cell.configure(with: task)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 3. Notify the HomeViewController that a row was clicked
        let selectedTask = incompleteTasks[indexPath.row]
        delegate?.didSelectLearningTask(selectedTask)
    }
}
