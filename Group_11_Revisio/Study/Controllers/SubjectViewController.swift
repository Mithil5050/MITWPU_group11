import UIKit
import UniformTypeIdentifiers
import SafariServices
import QuickLook

class SubjectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var materialsSegmentedControl: UISegmentedControl!
    @IBOutlet var topicsTableView: UITableView!
    @IBOutlet var filterButton: UIBarButtonItem!
    @IBOutlet var optionsButton: UIBarButtonItem!
    
    var selectedSubject: String?
    var currentContent: [Any] = []
    var currentFilterType: String = "All"
    var filteredContent: [Any] = []
    private let filterOptions: [String] = ["All", "Flashcards", "Quiz", "Cheatsheet", "Notes"]
    private var notificationToken: NSObjectProtocol?
    
    var doneSelectionButton: UIBarButtonItem!
    var cancelSelectionButton: UIBarButtonItem!
    var originalRightBarButtonItems: [UIBarButtonItem]?
    let searchController = UISearchController(searchResultsController: nil)
    var currentSortType: String = "Name"
    var isGridView: Bool = false
    
    var activeSegmentTitle: String {
        return materialsSegmentedControl.titleForSegment(at: materialsSegmentedControl.selectedSegmentIndex) ?? "Materials"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.toolbarItems = []
        let buttonColor: UIColor = .label
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        doneSelectionButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark"),
            primaryAction: UIAction { [weak self] _ in
                self?.selectionDoneTapped()
            }
        )
        doneSelectionButton.tintColor = buttonColor
        
        cancelSelectionButton = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in
                self?.selectionCancelTapped()
            }
        )
        cancelSelectionButton.tintColor = buttonColor
        
        if let selectedSubject {
            title = selectedSubject
            setupTableView()
            setupSearchController()
            loadContentForSubject(selectedSubject, segmentIndex: 0)
            setupFilterMenu()
            optionsButton.menu = setupOptionsMenu()
            self.originalRightBarButtonItems = self.navigationItem.rightBarButtonItems
        }
        
        topicsTableView.backgroundColor = .systemBackground
        view.backgroundColor = .systemBackground
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        materialsSegmentedControl.selectedSegmentIndex = 0
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.setToolbarHidden(true, animated: animated)
        
        notificationToken = NotificationCenter.default.addObserver(forName: .didUpdateStudyMaterials, object: nil, queue: .main) { [weak self] _ in
            if let subject = self?.selectedSubject {
                self?.loadContentForSubject(subject, segmentIndex: self?.materialsSegmentedControl.selectedSegmentIndex ?? 0)
            }
        }
        
        if let subject = selectedSubject {
            loadContentForSubject(subject, segmentIndex: materialsSegmentedControl.selectedSegmentIndex)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    func loadContentForSubject(_ subject: String, segmentIndex: Int) {
        let key = segmentKey(forIndex: segmentIndex)
        
        guard let subjectDict = DataManager.shared.savedMaterials[subject] else {
            self.currentContent = []
            topicsTableView.reloadData()
            return
        }
        
        if let content = subjectDict[key] {
            self.currentContent = content
        } else {
            self.currentContent = []
        }
        
        self.currentFilterType = "All"
        self.applyFilterAndReload()
    }
    
    func applyFilterAndReload() {
        let contentToFilter = currentContent
        
        if materialsSegmentedControl.selectedSegmentIndex == 1 {
            filteredContent = contentToFilter
        } else if currentFilterType == "All" {
            filteredContent = contentToFilter
        } else {
            filteredContent = contentToFilter.filter { item in
                guard let studyItem = item as? StudyItem else { return false }
                switch studyItem {
                case .topic(let topic):
                    return topic.materialType == currentFilterType
                case .source:
                    return false
                }
            }
        }

        if filteredContent.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No \(currentFilterType) items yet"
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.font = .preferredFont(forTextStyle: .headline)
            topicsTableView.backgroundView = emptyLabel
        } else {
            topicsTableView.backgroundView = nil
        }

        applySortAndReload()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return isGridView ? 140 : 76
    }
    
    func segmentKey(forIndex index: Int) -> String {
        return index == 0 ? DataManager.materialsKey : DataManager.sourcesKey
    }
    
    func handleDataUpdate() {
        if let subject = selectedSubject {
            loadContentForSubject(subject, segmentIndex: materialsSegmentedControl.selectedSegmentIndex)
        }
    }
    
    func setupTableView() {
        topicsTableView.delegate = self
        topicsTableView.dataSource = self
        
        let nib = UINib(nibName: "MaterialViewCell", bundle: nil)
        topicsTableView.register(nib, forCellReuseIdentifier: "MaterialViewCell")
        
        topicsTableView.separatorStyle = .none
        topicsTableView.rowHeight = 76
        topicsTableView.allowsMultipleSelectionDuringEditing = true
    }
    
    func setupSearchController() {
        searchController.searchBar.placeholder = "Search in \(selectedSubject ?? "this subject")"
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
    }
    
    func setupFilterMenu() {
        let actions: [UIAction] = filterOptions.map { filterName in
            let action = UIAction(title: filterName, handler: { [weak self] action in
                guard let self = self else { return }
                self.currentFilterType = action.title
                self.applyFilterAndReload()
                self.setupFilterMenu()
            })
            action.state = (filterName == currentFilterType) ? .on : .off
            return action
        }
        filterButton.menu = UIMenu(title: "Filter by Type", children: actions)
    }
    
    func setupOptionsMenu() -> UIMenu {
        let isSelectModeActive = topicsTableView.isEditing
        let currentSegment = materialsSegmentedControl.selectedSegmentIndex
        
        var addSubmenu: UIMenu?
        
        if currentSegment == 1 && !isSelectModeActive {
            addSubmenu = UIMenu(title: "Add Source", image: UIImage(systemName: "plus.circle"), children: [
                UIAction(title: "Document", image: UIImage(systemName: "text.document")) { [weak self] _ in
                    self?.presentDocumentPicker()
                },
                UIAction(title: "Photo / Media", image: UIImage(systemName: "photo.on.rectangle")) { [weak self] _ in
                    self?.presentImagePicker()
                },
                UIAction(title: "Link", image: UIImage(systemName: "link")) { [weak self] _ in
                    self?.showLinkInputAlert()
                },
                UIAction(title: "Text", image: UIImage(systemName: "textformat")) { [weak self] _ in
                            self?.showTextInputAlert()
                        }
                    
            ])
        }

        let displayMenu = UIMenu(title: "Display Options", options: .displayInline, children: [
            UIMenu(title: "View as", children: [
                UIAction(title: "List", state: isGridView ? .off : .on) { [weak self] _ in
                    self?.isGridView = false
                    self?.topicsTableView.reloadData()
                    self?.optionsButton.menu = self?.setupOptionsMenu()
                },
                UIAction(title: "Grid", state: isGridView ? .on : .off) { [weak self] _ in
                    self?.isGridView = true
                    self?.topicsTableView.reloadData()
                    self?.optionsButton.menu = self?.setupOptionsMenu()
                }
            ]),
            UIMenu(title: "Sort By", children: [
                UIAction(title: "Name", state: currentSortType == "Name" ? .on : .off) { [weak self] _ in
                    self?.currentSortType = "Name"
                    self?.applySortAndReload()
                    self?.optionsButton.menu = self?.setupOptionsMenu()
                },
                UIAction(title: "Date Created", state: currentSortType == "Date" ? .on : .off) { [weak self] _ in
                    self?.currentSortType = "Date"
                    self?.applySortAndReload()
                    self?.optionsButton.menu = self?.setupOptionsMenu()
                },
                UIAction(title: "Date Modified", state: currentSortType == "Modified" ? .on : .off) { [weak self] _ in
                    self?.currentSortType = "Modified"
                    self?.applySortAndReload()
                    self?.optionsButton.menu = self?.setupOptionsMenu()
                }
            ])
        ])

        var menuElements: [UIMenuElement] = []
        
        menuElements.append(UIAction(title: isSelectModeActive ? "Done" : "Select",
                                    image: UIImage(systemName: "checkmark.circle")) { [weak self] _ in
            guard let self = self else { return }
            if self.topicsTableView.isEditing {
                self.selectionDoneTapped()
            } else {
                self.topicsTableView.setEditing(true, animated: true)
                self.navigationItem.rightBarButtonItems = [self.doneSelectionButton]
                self.navigationItem.leftBarButtonItem = self.cancelSelectionButton
                self.updateToolbarForSelection()
                self.tabBarController?.tabBar.isHidden = true
            }
            self.optionsButton.menu = self.setupOptionsMenu()
        })

        if let addSubmenu = addSubmenu {
            menuElements.append(addSubmenu)
        }
        
        menuElements.append(UIAction(title: "Rename Subject", image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.renameCurrentSubject()
        })
        
        menuElements.append(UIMenu(title: "Management", children: [
            UIAction(title: "Move All Content", image: UIImage(systemName: "arrow.turn.forward")) { [weak self] _ in self?.moveAllContent() },
            UIAction(title: "Delete All Content", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in self?.deleteAllContent() }
        ]))
        
        menuElements.append(displayMenu)
        
        return UIMenu(title: "", children: menuElements)
    }
    func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .plainText, .text])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func showLinkInputAlert() {
        let alert = UIAlertController(title: "Add Web Link", message: "Enter a title and the URL", preferredStyle: .alert)
        
        alert.addTextField { $0.placeholder = "Title (e.g., Wikipedia)" }
        alert.addTextField { $0.placeholder = "https://..." }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let urlString = alert.textFields?[1].text, !urlString.isEmpty,
                  let subject = self?.selectedSubject else { return }
            
            let linkSource = Source(
                name: name,
                fileType: "LINK",
                size: urlString
            )
            
            DataManager.shared.addSource(to: subject, source: linkSource)
            self?.handleDataUpdate()
        }
        
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    func showTextInputAlert() {
        let alert = UIAlertController(title: "Add Text Source", message: "Enter a name for this note", preferredStyle: .alert)
        
        alert.addTextField { $0.placeholder = "Source Name (e.g., Lecture Summary)" }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let subject = self?.selectedSubject else { return }
            
            let textSource = Source(
                name: name,
                fileType: "TXT",   
                size: "Manual Note"
            )
            
            DataManager.shared.addSource(to: subject, source: textSource)
            self?.handleDataUpdate()
        }
        
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func getTitle(for item: Any) -> String {
        var rawName = ""
        if let studyItem = item as? StudyItem {
            switch studyItem {
            case .topic(let t): rawName = t.name
            case .source(let s): rawName = s.name
            }
        }
        else if let topic = item as? Topic { rawName = topic.name }
        else if let source = item as? Source { rawName = source.name }
        
        return cleanName(rawName) // ✅ Now returns "Physics" instead of "Note_Physics.txt"
    }
    
    func applySortAndReload() {
        filteredContent.sort { (item1, item2) -> Bool in
            if currentSortType == "Name" {
                return getTitle(for: item1).lowercased() < getTitle(for: item2).lowercased()
            } else if currentSortType == "Modified" {
                return getDate(for: item1) > getDate(for: item2)
            } else {
                return getDate(for: item1) < getDate(for: item2)
            }
        }
        topicsTableView.reloadData()
    }
    
    private func getDate(for item: Any) -> Date {
        let dateString: String
        if let studyItem = item as? StudyItem {
            switch studyItem {
            case .topic(let t): dateString = t.lastAccessed
            case .source: return Date.distantPast
            }
        } else if let topic = item as? Topic {
            dateString = topic.lastAccessed
        } else {
            return Date.distantPast
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.date(from: dateString) ?? Date.distantPast
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredContent.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MaterialViewCell", for: indexPath) as? MaterialViewCell else {
            return UITableViewCell()
        }
        
        if let studyItem = filteredContent[indexPath.row] as? StudyItem {
            cell.configure(with: studyItem)
            cell.onInfoButtonTapped = { [weak self] in
                self?.performSegue(withIdentifier: "ShowMaterialInfo", sender: studyItem)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateToolbarForSelection()
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let studyItem = filteredContent[indexPath.row] as? StudyItem else { return }
        
        switch studyItem {
        case .topic(let topic):
            handleTopicSelection(topic)
            
        case .source(let source):
            let type = source.fileType.uppercased()
            
            if type == "LINK" || type == "URL" {
                if let url = URL(string: source.size) {
                    let safariVC = SFSafariViewController(url: url)
                    present(safariVC, animated: true)
                }
            } else if type == "PDF" || type == "PNG" || type == "JPG" || type == "JPEG" {
                openFileWithQuickLook(fileName: source.name)
            } else {
                showSourcePreview(title: source.name, message: source.size)
            }
        }
    }
    private func handleTopicSelection(_ topic: Topic) {
        let latestTopic = DataManager.shared.getTopic(
            subjectName: self.selectedSubject ?? "",
            topicName: topic.name,
            type: topic.materialType
        ) ?? topic
        
        switch latestTopic.materialType {
        case "Quiz":
            if latestTopic.safeAttempts.isEmpty {
                performSegue(withIdentifier: "ShowInstructionScreen", sender: latestTopic)
            } else {
                performSegue(withIdentifier: "ShowQuizHistory", sender: latestTopic)
            }
        case "Flashcards":
            let modeVC = FlashcardStudyModeSelectionVC()
            if let sheet = modeVC.sheetPresentationController {
                if #available(iOS 16.0, *) {
                    sheet.detents = [.custom(resolver: { _ in return 340 })]
                } else {
                    sheet.detents = [.medium()]
                }
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 28
            }
            modeVC.onModeSelected = { [weak self] isChallenge in
                self?.pendingChallengeMode = isChallenge
                self?.performSegue(withIdentifier: "openFlashcards", sender: latestTopic)
            }
            self.present(modeVC, animated: true, completion: nil)
        default:
            performSegue(withIdentifier: "ShowMaterialDetail", sender: latestTopic)
        }
    }
    private func showSourcePreview(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Done", style: .cancel))
            present(alert, animated: true)
        }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing { updateToolbarForSelection() }
    }
    func openFileWithQuickLook(fileName: String) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            let previewController = QLPreviewController()
            previewController.dataSource = self
            self.currentPreviewURL = fileURL
            present(previewController, animated: true)
        } else {
            showSourcePreview(title: "Error", message: "File not found on device.")
        }
    }

    var currentPreviewURL: URL?
    private var pendingChallengeMode: Bool = false
    
    func updateToolbarForSelection() {
        let selectedCount = topicsTableView.indexPathsForSelectedRows?.count ?? 0
        let isSelectionActive = selectedCount > 0
        
        if !topicsTableView.isEditing {
            self.navigationController?.setToolbarHidden(true, animated: true)
            return
        }
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let primaryAction: UIBarButtonItem
        if activeSegmentTitle == "Sources" {
            primaryAction = UIBarButtonItem(title: "Generate", style: .plain, target: self, action: #selector(generateAction))
        } else {
            primaryAction = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(shareAction))
        }
        
        let deleteButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteSelectionAction))
        deleteButton.tintColor = .systemRed
        
        let textAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
        [deleteButton, primaryAction].forEach {
            $0.isEnabled = isSelectionActive
            $0.setTitleTextAttributes(textAttributes, for: .normal)
        }
        
        self.toolbarItems = [deleteButton, flexibleSpace, primaryAction]
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
    
    func exitSelectionMode() {
        self.navigationItem.rightBarButtonItems = self.originalRightBarButtonItems
        self.navigationItem.leftBarButtonItem = nil
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.tabBarController?.tabBar.isHidden = false
        self.optionsButton.menu = self.setupOptionsMenu()
    }
    
    func selectionDoneTapped() {
        topicsTableView.isEditing = false
        exitSelectionMode()
    }
    
    func selectionCancelTapped() {
        if let selected = topicsTableView.indexPathsForSelectedRows {
            for indexPath in selected {
                topicsTableView.deselectRow(at: indexPath, animated: false)
            }
        }
        topicsTableView.setEditing(false, animated: true)
        exitSelectionMode()
        topicsTableView.reloadData()
    }
    
    @objc func deleteSelectionAction() {
        guard let selectedPaths = topicsTableView.indexPathsForSelectedRows, !selectedPaths.isEmpty else { return }
        let selectedRawItems = getRawItems(from: selectedPaths)
        
        let alert = UIAlertController(title: "Delete Selected Items?", message: "Permanently delete \(selectedRawItems.count) items?", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            DataManager.shared.deleteItems(subjectName: self.selectedSubject ?? "", items: selectedRawItems)
            self.selectionCancelTapped()
            if let subject = self.selectedSubject {
                self.loadContentForSubject(subject, segmentIndex: self.materialsSegmentedControl.selectedSegmentIndex)
            }
        }
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc func moveSelectionAction() {
        guard let selectedPaths = topicsTableView.indexPathsForSelectedRows, !selectedPaths.isEmpty else { return }
        let selectedRawItems = getRawItems(from: selectedPaths)
        let otherSubjects = DataManager.shared.savedMaterials.keys.filter { $0 != selectedSubject }.sorted()
        
        if otherSubjects.isEmpty {
            let alert = UIAlertController(title: "No Destination", message: "Create another subject folder first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let moveAlert = UIAlertController(title: "Move \(selectedRawItems.count) Items", message: "Select destination folder", preferredStyle: .actionSheet)
        for subject in otherSubjects {
            moveAlert.addAction(UIAlertAction(title: subject, style: .default) { [weak self] _ in
                guard let self = self else { return }
                DataManager.shared.moveItems(items: selectedRawItems, from: self.selectedSubject ?? "", to: subject)
                self.selectionDoneTapped()
                if let current = self.selectedSubject { self.loadContentForSubject(current, segmentIndex: self.materialsSegmentedControl.selectedSegmentIndex) }
            })
        }
        moveAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(moveAlert, animated: true)
    }
    
    func renameMaterialAction(for item: Any) {
        let currentName = (item as? Topic)?.name ?? (item as? Source)?.name ?? ""
        let alert = UIAlertController(title: "Rename Material", message: "Enter a new name", preferredStyle: .alert)
        alert.addTextField { $0.text = currentName }
        
        let rename = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            DataManager.shared.renameMaterial(subjectName: self.selectedSubject ?? "", item: item, newName: newName)
            if let subject = self.selectedSubject { self.loadContentForSubject(subject, segmentIndex: self.materialsSegmentedControl.selectedSegmentIndex) }
        }
        alert.addAction(rename)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }
            
            let item = self.filteredContent[indexPath.row]
            let rawItem = self.unwrapStudyItem(item)
            
            let rename = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in
                self.renameMaterialAction(for: rawItem)
            }
            
            let move = UIAction(title: "Move to Folder", image: UIImage(systemName: "arrowshape.turn.up.right")) { _ in
                self.moveSingleItem(rawItem)
            }
            
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.deleteSingleItem(rawItem)
            }
            
            return UIMenu(title: "", children: [rename, move, delete])
        }
    }

    func moveSingleItem(_ item: Any) {
        let otherSubjects = DataManager.shared.savedMaterials.keys.filter { $0 != selectedSubject }.sorted()
        
        if otherSubjects.isEmpty {
            let alert = UIAlertController(title: "No Destination", message: "Create another subject folder first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        let moveAlert = UIAlertController(title: "Move Item", message: "Select destination folder", preferredStyle: .actionSheet)
        for subject in otherSubjects {
            moveAlert.addAction(UIAlertAction(title: subject, style: .default) { [weak self] _ in
                guard let self = self else { return }
                DataManager.shared.moveItems(items: [item], from: self.selectedSubject ?? "", to: subject)
                self.handleDataUpdate()
            })
        }
        moveAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(moveAlert, animated: true)
    }

    func deleteSingleItem(_ item: Any) {
        let alert = UIAlertController(title: "Delete Item?", message: "This will permanently remove this item.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            DataManager.shared.deleteItems(subjectName: self.selectedSubject ?? "", items: [item])
            self.handleDataUpdate()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func unwrapStudyItem(_ item: Any) -> Any {
        if let studyItem = item as? StudyItem {
            switch studyItem {
            case .topic(let topic): return topic
            case .source(let source): return source
            }
        }
        return item
    }
    
    @objc func renameCurrentSubject() {
        guard let oldName = selectedSubject else { return }
        presentRenameAlert(for: oldName) { [weak self] newName in
            guard let self = self else { return }
            DataManager.shared.renameSubject(oldName: oldName, newName: newName)
            self.selectedSubject = newName
            self.title = newName
            self.loadContentForSubject(newName, segmentIndex: self.materialsSegmentedControl.selectedSegmentIndex)
            NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        }
    }
    
    @objc func deleteAllContent() {
        let alert = UIAlertController(
            title: "Delete All Content?",
            message: "This will permanently remove all materials and sources from \(selectedSubject ?? "this subject"). This action cannot be undone.",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete Everything", style: .destructive) { [weak self] _ in
            guard let self = self, let subject = self.selectedSubject else { return }
            DataManager.shared.deleteItems(subjectName: subject, items: self.currentContent)
            self.loadContentForSubject(subject, segmentIndex: self.materialsSegmentedControl.selectedSegmentIndex)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    @objc func moveAllContent() {
        let otherSubjects = DataManager.shared.savedMaterials.keys.filter { $0 != selectedSubject }.sorted()
        
        if otherSubjects.isEmpty {
            let alert = UIAlertController(title: "No Destination", message: "Create another subject folder first to move content.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let moveAlert = UIAlertController(title: "Move All Content", message: "Select a destination folder for all items in \(selectedSubject ?? "this subject")", preferredStyle: .actionSheet)
        
        for destination in otherSubjects {
            moveAlert.addAction(UIAlertAction(title: destination, style: .default) { [weak self] _ in
                guard let self = self, let current = self.selectedSubject else { return }
                DataManager.shared.moveItems(items: self.currentContent, from: current, to: destination)
                self.loadContentForSubject(current, segmentIndex: self.materialsSegmentedControl.selectedSegmentIndex)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            })
        }
        
        moveAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = moveAlert.popoverPresentationController {
            popover.barButtonItem = optionsButton
        }
        present(moveAlert, animated: true)
    }
    
    @IBAction func segmentControlTapped(_ sender: UISegmentedControl) {
        if let subject = selectedSubject {
            loadContentForSubject(subject, segmentIndex: sender.selectedSegmentIndex)
        }
        optionsButton.menu = setupOptionsMenu()
        
        if sender.selectedSegmentIndex == 0 {
            filterButton.isEnabled = true
            filterButton.tintColor = .label
        } else {
            filterButton.isEnabled = false
            filterButton.tintColor = .systemGray
            self.currentFilterType = "All"
        }
    }
    
    private func getRawItems(from indexPaths: [IndexPath]) -> [Any] {
        return indexPaths.compactMap { indexPath in
            if let studyItem = filteredContent[indexPath.row] as? StudyItem {
                switch studyItem {
                case .topic(let topic): return topic
                case .source(let source): return source
                }
            }
            return nil
        }
    }
    
    @objc func generateAction() {
        guard let selectedPaths = topicsTableView.indexPathsForSelectedRows else { return }
        let selectedRawItems = getRawItems(from: selectedPaths)
        performSegue(withIdentifier: "ShowGenerationScreen", sender: selectedRawItems)
    }
    
    @objc func shareAction() {
        guard let selectedPaths = topicsTableView.indexPathsForSelectedRows, !selectedPaths.isEmpty else { return }
        
        let selectedRawItems = getRawItems(from: selectedPaths)
        var itemsToShare: [Any] = []
        
        for item in selectedRawItems {
            if let topic = item as? Topic {
                let shareText = "Check out my \(topic.materialType) for \(selectedSubject ?? "Subject"): \(topic.name)"
                itemsToShare.append(shareText)
            }
        }
        
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        if let popover = activityViewController.popoverPresentationController {
            popover.barButtonItem = self.toolbarItems?.last
        }
        
        present(activityViewController, animated: true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var finalTopic: Topic?
        
        // 1. Identify and Unwrap the Topic
        if let studyItem = sender as? StudyItem, case .topic(let topic) = studyItem {
            var foundTopic = topic
            if let subject = self.selectedSubject,
               let materials = DataManager.shared.savedMaterials[subject]?[DataManager.materialsKey] {
                for item in materials {
                    if case .topic(let t) = item, t.name == topic.name, t.materialType == topic.materialType {
                        foundTopic = t
                        break
                    }
                }
            }
            finalTopic = foundTopic
        } else if let topic = sender as? Topic {
            finalTopic = topic
        }
        
        // 2. Handle Specific Segues with Clean Naming
        if segue.identifier == "ShowQuizHistory" {
            if let historyVC = segue.destination as? QuizHistoryViewController,
               let topic = finalTopic {
                historyVC.quizTopic = topic
                historyVC.parentSubject = self.selectedSubject
                // Clean title for history screen
                historyVC.title = cleanName(topic.name)
            }
        }
        else if segue.identifier == "ShowMaterialInfo",
                let infoVC = segue.destination as? MaterialInfoViewController,
                let studyItem = sender as? StudyItem {
            
            infoVC.originalItem = studyItem
            infoVC.parentSubject = self.selectedSubject
            
            switch studyItem {
            case .topic(let topic):
                infoVC.materialName = cleanName(topic.name) // ✅ Cleaned
                infoVC.materialType = topic.materialType
                infoVC.dateCreated = topic.createdDate ?? topic.lastAccessed ?? "Just now"
                infoVC.sourceName = cleanName(topic.sourceName ?? "Attached Document") // ✅ Cleaned
                
                // Icon Logic...
                switch topic.materialType {
                case "Quiz": infoVC.iconName = "timer"; infoVC.iconColor = UIColor(hex: "88D769")
                case "Notes": infoVC.iconName = "book.pages"; infoVC.iconColor = UIColor(hex: "FFC445", alpha: 0.75)
                case "Flashcards": infoVC.iconName = "rectangle.on.rectangle.angled"; infoVC.iconColor = UIColor(hex: "91C1EF")
                case "Cheatsheet": infoVC.iconName = "list.clipboard"; infoVC.iconColor = UIColor(hex: "8A38F5", alpha: 0.50)
                default: infoVC.iconName = "doc.text.fill"; infoVC.iconColor = .systemGray
                }
                
            case .source(let source):
                infoVC.materialName = cleanName(source.name) // ✅ Cleaned
                infoVC.materialType = source.fileType
                infoVC.dateCreated = "Added Recently"
                let type = source.fileType.uppercased()
                infoVC.iconName = (type == "IMAGE" || type == "JPG") ? "photo.fill" : "doc.text.fill"
                infoVC.iconColor = .systemIndigo
            }
        }
        else if segue.identifier == "ShowMaterialDetail",
                let detailVC = segue.destination as? MaterialDetailViewController,
                let topic = finalTopic {
            detailVC.materialName = cleanName(topic.name) // ✅ Cleaned
            detailVC.contentData = topic
            detailVC.parentSubjectName = selectedSubject
            detailVC.materialType = topic.materialType
            detailVC.title = cleanName(topic.name) // ✅ Cleaned
        }
        else if segue.identifier == "ShowNotes",
                let dest = segue.destination as? NotesViewController,
                let topic = finalTopic {
            dest.currentTopic = topic
            dest.parentSubjectName = self.selectedSubject
            dest.title = cleanName(topic.name) // ✅ Cleaned
        }
        else if segue.identifier == "ShowCheatsheet",
                let dest = segue.destination as? CheatsheetViewController,
                let topic = finalTopic {
            dest.currentTopic = topic
            dest.parentSubjectName = self.selectedSubject
            dest.title = cleanName(topic.name) // ✅ Cleaned
        }
        else if segue.identifier == "ShowInstructionScreen",
                let instructionVC = segue.destination as? QuizStartViewController,
                let topic = finalTopic {
            instructionVC.currentTopic = topic
            instructionVC.parentSubject = selectedSubject
            // Important: instructionVC uses topic name internally for the big label
        }
        else if segue.identifier == "openFlashcards",
                let flashVC = segue.destination as? FlashcardsViewController,
                let topic = finalTopic {
            flashVC.currentTopic = topic
            flashVC.parentSubjectName = self.selectedSubject
            flashVC.title = cleanName(topic.name) // ✅ Cleaned
            flashVC.startInChallengeMode = self.pendingChallengeMode
        }
        else if segue.identifier == "ShowGenerationScreen",
                let generationVC = segue.destination as? GenerationViewController,
                let items = sender as? [Any] {
            generationVC.sourceItems = items
            generationVC.parentSubjectName = selectedSubject
            generationVC.title = "Generate"
            selectionCancelTapped()
        }
    }
    private func cleanName(_ rawName: String) -> String {
        return rawName.replacingOccurrences(of: ".txt", with: "")
                      .replacingOccurrences(of: "Note_", with: "")
                      .replacingOccurrences(of: "Link_", with: "")
                      .replacingOccurrences(of: "Image_", with: "")
                      .replacingOccurrences(of: "_", with: " ")
                      .trimmingCharacters(in: .whitespaces)
    }
}

extension SubjectViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else { return }
        
        if searchText.isEmpty {
            applyFilterAndReload()
        } else {
            filteredContent = currentContent.compactMap { item -> StudyItem? in
                guard let studyItem = item as? StudyItem else { return nil }
                let title = getTitle(for: studyItem).lowercased()
                
                if title.contains(searchText) {
                    return studyItem
                }
                return nil
            }
            
            if filteredContent.isEmpty {
                let emptyLabel = UILabel()
                emptyLabel.text = "No results for '\(searchText)'"
                emptyLabel.textAlignment = .center
                emptyLabel.textColor = .secondaryLabel
                topicsTableView.backgroundView = emptyLabel
            } else {
                topicsTableView.backgroundView = nil
            }
            
            topicsTableView.reloadData()
        }
    }
}
extension SubjectViewController: UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, let subject = selectedSubject else { return }
        
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            
            DataManager.shared.importFile(url: url, subject: subject)
            
            self.handleDataUpdate()
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            print("✅ Document successfully imported to \(subject)")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        print("✅ Finished picking image")
    }
}
extension SubjectViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return currentPreviewURL! as QLPreviewItem
    }
}

// MARK: - Flashcard Mode Selection Custom Native Sheet
class FlashcardStudyModeSelectionVC: UIViewController {
    var onModeSelected: ((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Select Study Mode"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        
        let normalBtn = ModeCardButton(
            title: "Normal Mode",
            desc: "Standard visual review. Tap to flip.",
            icon: "rectangle.portrait.on.rectangle.portrait",
            accentColor: .systemBlue
        )
        normalBtn.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true) { self?.onModeSelected?(false) }
        }, for: .touchUpInside)
        
        let challengeBtn = ModeCardButton(
            title: "Challenge Mode",
            desc: "Test your memory. Type the exact term.",
            icon: "keyboard",
            accentColor: UIColor(red: 0.86, green: 0.24, blue: 0.96, alpha: 1.0)
        )
        challengeBtn.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true) { self?.onModeSelected?(true) }
        }, for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, normalBtn, challengeBtn])
        stack.axis = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(24, after: titleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
}

class ModeCardButton: UIControl {
    private let title: String
    private let desc: String
    private let icon: String
    private let accentColor: UIColor
    
    init(title: String, desc: String, icon: String, accentColor: UIColor) {
        self.title = title
        self.desc = desc
        self.icon = icon
        self.accentColor = accentColor
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupView() {
        backgroundColor = accentColor.withAlphaComponent(0.12)
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.0
        layer.borderColor = accentColor.withAlphaComponent(0.2).cgColor
        
        // Touch feedback
        addTarget(self, action: #selector(touchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchDragExit, .touchCancel])
        
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)))
        iconView.tintColor = accentColor
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconBg = UIView()
        iconBg.backgroundColor = accentColor.withAlphaComponent(0.18)
        iconBg.layer.cornerRadius = 14
        iconBg.layer.cornerCurve = .continuous
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconView)
        
        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 56),
            iconBg.heightAnchor.constraint(equalToConstant: 56),
            iconView.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = .label
        
        let descLabel = UILabel()
        descLabel.text = desc
        descLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.alignment = .leading
        
        let hStack = UIStackView(arrangedSubviews: [iconBg, textStack])
        hStack.axis = .horizontal
        hStack.spacing = 18
        hStack.alignment = .center
        hStack.isUserInteractionEnabled = false
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) { self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96); self.alpha = 0.8 }
    }
    
    @objc private func touchUp() {
        UIView.animate(withDuration: 0.2) { self.transform = .identity; self.alpha = 1.0 }
    }
}
