import UIKit

class MaterialInfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var materialName: String = ""
    var materialType: String = ""
    var sourceName: String = ""
    var dateCreated: String = ""
    var iconName: String = ""
    var iconColor: UIColor = .systemBlue

    var parentSubject: String?
    var originalItem: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableHeaderView = createHeaderView()
    }

    func createHeaderView() -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 160))
        
        let container = UIView()
        container.backgroundColor = iconColor.withAlphaComponent(0.12)
        container.layer.cornerRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(container)
        
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .semibold)
        imageView.image = UIImage(systemName: iconName, withConfiguration: config)
        imageView.tintColor = iconColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        
        let titleLabel = UILabel()
        titleLabel.text = materialName
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = materialType
        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            container.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            container.widthAnchor.constraint(equalToConstant: 72),
            container.heightAnchor.constraint(equalToConstant: 72),
            
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -30),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor)
        ])
        
        return headerView
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 3 : 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath)
            cell.selectionStyle = .none
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
            cell.detailTextLabel?.font = .preferredFont(forTextStyle: .body)
            cell.detailTextLabel?.textColor = .secondaryLabel
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Material Type"
                cell.detailTextLabel?.text = materialType
            case 1:
                cell.textLabel?.text = "Source Name"
                cell.detailTextLabel?.text = sourceName
            case 2:
                cell.textLabel?.text = "Created"
                cell.detailTextLabel?.text = dateCreated
            default: break
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath)
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Rename"
                cell.textLabel?.textColor = .systemBlue
                cell.imageView?.image = UIImage(systemName: "pencil")
            } else {
                cell.textLabel?.text = "Delete"
                cell.textLabel?.textColor = .systemRed
                cell.imageView?.image = UIImage(systemName: "trash")
                cell.imageView?.tintColor = .systemRed
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                renameItem()
            } else {
                deleteItem()
            }
        }
    }

    private func renameItem() {
        let alert = UIAlertController(title: "Rename Material", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = self.materialName }
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty,
                  let item = self.originalItem, let subject = self.parentSubject else { return }
            
            DataManager.shared.renameMaterial(subjectName: subject, item: item, newName: newName)
            self.materialName = newName
            self.tableView.tableHeaderView = self.createHeaderView()
            NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func deleteItem() {
        let alert = UIAlertController(title: "Delete Material", message: "This item will be permanently removed.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            guard let item = self.originalItem, let subject = self.parentSubject else { return }
            
            let itemToDelete: Any
            if let studyItem = item as? StudyItem {
                switch studyItem {
                case .topic(let topic): itemToDelete = topic
                case .source(let source): itemToDelete = source
                }
            } else {
                itemToDelete = item
            }
            
            DataManager.shared.deleteItems(subjectName: subject, items: [itemToDelete])
            NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
            self.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
