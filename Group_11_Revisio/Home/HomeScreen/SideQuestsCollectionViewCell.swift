import UIKit

protocol SideQuestDelegate: AnyObject {
    func didUpdateQuests(_ quests: [SideQuest])
    func didEarnXP(amount: Int, sourceView: UIView)
}

class SideQuestsCollectionViewCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, QuestCellDelegate {

    // MARK: - Outlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    weak var delegate: SideQuestDelegate?
    var quests: [SideQuest] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupTable()
    }
    
    func setupUI() {
        containerView.layer.cornerRadius = 16
        containerView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        
        inputTextField.delegate = self
        inputTextField.attributedPlaceholder = NSAttributedString(
            string: "Add a focus task...",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        inputTextField.textColor = .white
    }
    
    func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "QuestTableViewCell", bundle: nil), forCellReuseIdentifier: "QuestTableViewCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
    }
    
    // MARK: - Dynamic Resizing Logic
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: UIView.layoutFittingCompressedSize.height)
        let newSize = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        var newFrame = layoutAttributes.frame
        newFrame.size.height = ceil(newSize.height)
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }
    
    func configure(with quests: [SideQuest]) {
        self.quests = quests
        tableView.reloadData()
        updateHeight()
    }
    
    func updateHeight() {
        let count = CGFloat(quests.count)
        tableHeightConstraint.constant = max(50, count * 50)
    }

    // MARK: - Add Task
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, !text.isEmpty else { return true }
        if quests.count >= 5 { return true }
        
        let newQuest = SideQuest(title: text)
        quests.append(newQuest)
        
        textField.text = ""
        textField.resignFirstResponder()
        tableView.reloadData()
        updateHeight()
        delegate?.didUpdateQuests(quests)
        return true
    }

    // MARK: - Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return quests.count }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 50 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuestTableViewCell", for: indexPath) as! QuestTableViewCell
        cell.configure(with: quests[indexPath.row])
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            quests.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateHeight()
            delegate?.didUpdateQuests(quests)
        }
    }
    
    // MARK: - Task Done (Vanish Logic)
    func didToggleQuest(cell: QuestTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        // 1. Give XP
        delegate?.didEarnXP(amount: 10, sourceView: cell.checkButton)
        
        // 2. Remove Task
        quests.remove(at: indexPath.row)
        
        // 3. Vanish Animation
        tableView.deleteRows(at: [indexPath], with: .fade)
        
        // 4. Resize
        updateHeight()
        delegate?.didUpdateQuests(quests)
    }
}
