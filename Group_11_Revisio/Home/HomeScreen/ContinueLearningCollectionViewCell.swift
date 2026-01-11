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
        ViewShow.layer.cornerRadius = 12
        ViewShow.backgroundColor = UIColor(hex: "FFFFFF")
        LogoView.layer.cornerRadius = 8
        LogoView.backgroundColor = UIColor(hex: "74DA9B" , alpha: 0.15)
        quizlogo.tintColor = UIColor(hex: "74DA9B")
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
