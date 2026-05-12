import UIKit

class StudyFolderViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let studyTableView = UITableView(frame: .zero, style: .plain)
    private var subjectNames: [String] = []

    // MARK: - Empty State Views
    private let emptyStateView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let emptyMascotImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bot_pencil")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "No Folders Yet"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emptySubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create a folder to organize\nyour study materials"
        label.textColor = .lightGray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()


    private var materialUpdateToken: NSObjectProtocol?
    private var folderUpdateToken: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNotificationObservers()
        fetchFolderNames()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFolderNames()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let materialToken = materialUpdateToken { NotificationCenter.default.removeObserver(materialToken) }
        if let folderToken = folderUpdateToken { NotificationCenter.default.removeObserver(folderToken) }
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(studyTableView)

        // Empty state
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyMascotImageView)
        emptyStateView.addSubview(emptyTitleLabel)
        emptyStateView.addSubview(emptySubtitleLabel)

        studyTableView.translatesAutoresizingMaskIntoConstraints = false
        studyTableView.layer.cornerRadius = 12.0
        studyTableView.clipsToBounds = true
        studyTableView.dataSource = self
        studyTableView.delegate = self
        studyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "StudyCell")

        if #available(iOS 15.0, *) {
            studyTableView.sectionHeaderTopPadding = 0
        }

        studyTableView.contentInsetAdjustmentBehavior = .never
    }

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            studyTableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            studyTableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            studyTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            studyTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Empty state container
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            emptyMascotImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyMascotImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyMascotImageView.widthAnchor.constraint(equalToConstant: 160),
            emptyMascotImageView.heightAnchor.constraint(equalToConstant: 160),

            emptyTitleLabel.topAnchor.constraint(equalTo: emptyMascotImageView.bottomAnchor, constant: 20),
            emptyTitleLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyTitleLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),

            emptySubtitleLabel.topAnchor.constraint(equalTo: emptyTitleLabel.bottomAnchor, constant: 10),
            emptySubtitleLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptySubtitleLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptySubtitleLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }

    private func setupNotificationObservers() {
       
        materialUpdateToken = NotificationCenter.default.addObserver(forName: .didUpdateStudyMaterials, object: nil, queue: .main) { [weak self] _ in
            self?.fetchFolderNames()
        }

        folderUpdateToken = NotificationCenter.default.addObserver(forName: .didUpdateStudyFolders, object: nil, queue: .main) { [weak self] _ in
            self?.fetchFolderNames()
        }
    }

    private func fetchFolderNames() {
        self.subjectNames = Array(DataManager.shared.savedMaterials.keys).sorted()

        if subjectNames.isEmpty {
            studyTableView.isHidden = true
            emptyStateView.isHidden = false
        } else {
            studyTableView.isHidden = false
            emptyStateView.isHidden = true
        }

        studyTableView.reloadData()
    }

    private func executeDeletion(at indexPath: IndexPath) {
        let subjectToDelete = self.subjectNames[indexPath.row]

        DataManager.shared.deleteSubjectFolder(name: subjectToDelete)

        self.subjectNames.remove(at: indexPath.row)
        self.studyTableView.deleteRows(at: [indexPath], with: .fade)

        if subjectNames.isEmpty {
            fetchFolderNames()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      
        if segue.identifier == "ShowSubjectDetailProgrammatic",
           let detailVC = segue.destination as? SubjectViewController,
           let selectedSubject = sender as? String {
            detailVC.selectedSubject = selectedSubject
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subjectNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StudyCell", for: indexPath)
        
        cell.textLabel?.text = subjectNames[indexPath.row]
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.imageView?.image = UIImage(systemName: "folder")
        cell.imageView?.tintColor = .systemBlue
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.text = "Your Materials"
        
        label.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16)
        ])
        
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedSubjectName = subjectNames[indexPath.row]
        performSegue(withIdentifier: "ShowSubjectDetailProgrammatic", sender: selectedSubjectName)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let folderName = self.subjectNames[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }
            
            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in
                self.presentRenameAlert(for: folderName) { newName in
                    DataManager.shared.renameSubject(oldName: folderName, newName: newName)
                    NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
                    self.fetchFolderNames()
                }
            }
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.executeDeletion(at: indexPath)
            }
            
            return UIMenu(title: folderName, children: [renameAction, deleteAction])
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            let subject = self?.subjectNames[indexPath.row] ?? ""
            
            let alert = UIAlertController(title: "Delete '\(subject)'?", message: "Permanently remove all materials inside?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self?.executeDeletion(at: indexPath)
                completionHandler(true)
            })
            
            self?.present(alert, animated: true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
