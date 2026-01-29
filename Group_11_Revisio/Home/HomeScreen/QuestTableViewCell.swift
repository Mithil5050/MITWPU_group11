import UIKit

protocol QuestCellDelegate: AnyObject {
    func didToggleQuest(cell: QuestTableViewCell)
}

class QuestTableViewCell: UITableViewCell {

    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var strikeLine: UIView!
    
    weak var delegate: QuestCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        selectionStyle = .none
        
        checkButton.layer.borderWidth = 2
        checkButton.layer.cornerRadius = 12
        checkButton.layer.borderColor = UIColor.lightGray.cgColor
        checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)
        
        strikeLine.isHidden = true
    }

    func configure(with quest: SideQuest) {
        titleLabel.text = quest.title
        checkButton.layer.borderColor = UIColor.systemIndigo.cgColor
        strikeLine.isHidden = true
    }
    
    @objc func checkTapped() {
        delegate?.didToggleQuest(cell: self)
    }
}
