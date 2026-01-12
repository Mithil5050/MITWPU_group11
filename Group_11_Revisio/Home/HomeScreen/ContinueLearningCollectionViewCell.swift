import UIKit

class ContinueLearningCollectionViewCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet var quizlogo: UIImageView!
    @IBOutlet var LogoView: UIView!
    @IBOutlet var ViewShow: UIView!
    var incompleteTasks: [PlanTask] = []
    
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return incompleteTasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LearningTaskCell", for: indexPath) as? LearningTaskCell else {
            return UITableViewCell()
        }
        
        let planItem = incompleteTasks[indexPath.row]
        
        // LOGIC RESTORED: Map your data to the Advanced format
        // We alternate types based on row number just to show variety (Quiz vs Notes)
        let isEven = indexPath.row % 2 == 0
        
        let task = LearningTask(
            title: planItem.title,
            subtitle: nil, // We let the cell generate the "modules remaining" text
            remainingModules: Int.random(in: 3...10), // Random number for demo
            type: isEven ? .notes : .quiz             // Alternating icons
        )
        
        cell.configure(with: task)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
