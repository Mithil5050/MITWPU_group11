import UIKit

class SubjectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Outlets
    @IBOutlet var materialsSegmentedControl: UISegmentedControl!
    @IBOutlet var topicsTableView: UITableView!
    @IBOutlet var filterButton: UIBarButtonItem!
    @IBOutlet var optionsButton: UIBarButtonItem!
    
    // MARK: - Properties
    var selectedSubject: String?
    var currentContent: [Any] = []
    var currentFilterType: String = "All"
    var filteredContent: [Any] = []
    private let filterOptions: [String] = ["All", "Flashcards", "Quiz", "Cheatsheet", "Notes"]
    
    var doneSelectionButton: UIBarButtonItem!
    var cancelSelectionButton: UIBarButtonItem!
    var originalRightBarButtonItems: [UIBarButtonItem]?
    let searchController = UISearchController(searchResultsController: nil)

    var activeSegmentTitle: String {
        return materialsSegmentedControl.titleForSegment(at: materialsSegmentedControl.selectedSegmentIndex) ?? "Materials"
    }

    // MARK: - Lifecycle (App Start)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.toolbarItems = []
        
        
        let buttonColor: UIColor = .label
        
        doneSelectionButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark"),
            style: .plain,
            target: self,
            action: #selector(selectionDoneTapped)
        )
        doneSelectionButton.tintColor = buttonColor
        cancelSelectionButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(selectionCancelTapped))
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
        // Reset view state when coming back to this screen
        materialsSegmentedControl.selectedSegmentIndex = 0
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.setToolbarHidden(true, animated: animated)
        
        // Listen for data changes so the list stays updated
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataUpdate), name: .didUpdateStudyMaterials, object: nil)
        
        if let subject = selectedSubject {
            loadContentForSubject(subject, segmentIndex: materialsSegmentedControl.selectedSegmentIndex)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .didUpdateStudyMaterials, object: nil)
    }

    // MARK: - Data Logic (Loading & Filtering)
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
        
        if currentFilterType == "All" {
            filteredContent = contentToFilter
        } else {
            // Only show items that match the selected filter (Quiz, Notes, etc.)
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
        topicsTableView.reloadData()
    }

    func segmentKey(forIndex index: Int) -> String {
        return index == 0 ? DataManager.materialsKey : DataManager.sourcesKey
    }

    @objc func handleDataUpdate() {
        if let subject = selectedSubject {
            loadContentForSubject(subject, segmentIndex: materialsSegmentedControl.selectedSegmentIndex)
        }
    }

    // MARK: - UI Setup (Menus & Table Configuration)
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
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
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
        
        let selectAction = UIAction(title: isSelectModeActive ? "Done" : "Select",
                                    image: UIImage(systemName: "checkmark.circle"),
                                    handler: { [weak self] action in
            guard let self = self else { return }
            
            if self.topicsTableView.isEditing {
                self.selectionDoneTapped()
            } else {
                // Enter Selection Mode
                self.topicsTableView.setEditing(true, animated: true)
                self.navigationItem.rightBarButtonItems = [self.doneSelectionButton]
                self.navigationItem.leftBarButtonItem = self.cancelSelectionButton
                self.updateToolbarForSelection()
                self.tabBarController?.tabBar.isHidden = true
            }
            
            DispatchQueue.main.async {
                self.optionsButton.menu = self.setupOptionsMenu()
            }
        })
        
        let renameAction = UIAction(title: "Rename Subject", image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.renameCurrentSubject()
        }
        
        let moveAllAction = UIAction(title: "Move All Content", image: UIImage(systemName: "arrow.turn.forward"), handler: { [weak self] _ in
            self?.moveAllContent()
        })
        
        let deleteAllAction = UIAction(title: "Delete All Content", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { [weak self] _ in
            self?.deleteAllContent()
        })
        
        let menu = UIMenu(title: "Option", children: [
            selectAction,
            renameAction,
            UIMenu(title: "Management", children: [moveAllAction, deleteAllAction]),
            UIMenu(title: "Display Options", options: .displayInline, children: [
                UIAction(title: "View as", image: UIImage(systemName: "list.bullet.indent"), handler: { _ in }),
                UIAction(title: "Sort By", image: UIImage(systemName: "arrow.up.arrow.down"), handler: { _ in })
            ])
        ])
        
        return menu
    }

    // MARK: - TableView Methods (Data Display)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredContent.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MaterialViewCell", for: indexPath) as? MaterialViewCell else {
            return UITableViewCell()
        }
        
        if let studyItem = filteredContent[indexPath.row] as? StudyItem {
            cell.configure(with: studyItem)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateToolbarForSelection()
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            guard let studyItem = filteredContent[indexPath.row] as? StudyItem else { return }
            
            switch studyItem {
            case .topic(let topic):
                if ["Notes", "Cheatsheet"].contains(topic.materialType) {
                    performSegue(withIdentifier: "ShowMaterialDetail", sender: topic)
                } else if topic.materialType == "Quiz" {
                    performSegue(withIdentifier: "ShowInstructionScreen", sender: topic)
                } else if topic.materialType == "Flashcards" {
                    performSegue(withIdentifier: "openFlashcards", sender: topic)
                }
            case .source(let source):
                print("Opening source: \(source.name)")
            }
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing { updateToolbarForSelection() }
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    // MARK: - Selection & Toolbar Logic
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
            primaryAction = UIBarButtonItem(title: "Generate", image: UIImage(systemName: "wand.and.stars"), target: self, action: #selector(generateAction))
        } else {
            primaryAction = UIBarButtonItem(title: "Share", image: UIImage(systemName: "square.and.arrow.up"), target: self, action: #selector(shareAction))
        }

        let deleteButton = UIBarButtonItem(title: "Delete", image: UIImage(systemName: "trash"), target: self, action: #selector(deleteSelectionAction))
        deleteButton.tintColor = .systemRed

        let moveButton = UIBarButtonItem(title: "Move", image: UIImage(systemName: "arrowshape.turn.up.right"), target: self, action: #selector(moveSelectionAction))

        [deleteButton, moveButton, primaryAction].forEach { $0.isEnabled = isSelectionActive }
        
        self.toolbarItems = [deleteButton, flexibleSpace, moveButton, flexibleSpace, primaryAction]
        self.navigationController?.setToolbarHidden(false, animated: true)
    }

    func exitSelectionMode() {
        self.navigationItem.rightBarButtonItems = self.originalRightBarButtonItems
        self.navigationItem.leftBarButtonItem = nil
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.tabBarController?.tabBar.isHidden = false
        self.optionsButton.menu = self.setupOptionsMenu()
    }

    @objc func selectionDoneTapped() {
        topicsTableView.isEditing = false
        exitSelectionMode()
    }

    @objc func selectionCancelTapped() {
        if let selected = topicsTableView.indexPathsForSelectedRows {
            for indexPath in selected {
                topicsTableView.deselectRow(at: indexPath, animated: false)
            }
        }
        topicsTableView.setEditing(false, animated: true)
        exitSelectionMode()
        topicsTableView.reloadData()
    }

    // MARK: - Actions (Delete, Move, Rename)
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

    // MARK: - Global Folder Actions
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

    @objc func moveAllContent() { print("Moving all content...") }
    @objc func deleteAllContent() { print("Deleting all content...") }

    // MARK: - Helpers & Segues
    @IBAction func segmentControlTapped(_ sender: Any) {
        if let subject = selectedSubject {
            loadContentForSubject(subject, segmentIndex: (sender as AnyObject).selectedSegmentIndex)
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

    @objc func shareAction() { print("Sharing items...") }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var finalTopic: Topic?
        if let topic = sender as? Topic { finalTopic = topic }
        else if let studyItem = sender as? StudyItem, case .topic(let topic) = studyItem { finalTopic = topic }

        if segue.identifier == "ShowMaterialDetail", let detailVC = segue.destination as? MaterialDetailViewController, let topic = finalTopic {
            detailVC.materialName = topic.name
            detailVC.contentData = topic
            detailVC.parentSubjectName = selectedSubject
        } else if segue.identifier == "ShowInstructionScreen", let instructionVC = segue.destination as? InstructionViewController, let topic = finalTopic {
            instructionVC.quizTopic = topic
            instructionVC.parentSubjectName = selectedSubject
        } else if segue.identifier == "openFlashcards", let flashVC = segue.destination as? FlashcardsViewController, let topic = finalTopic {
            flashVC.currentTopic = topic
            flashVC.parentSubjectName = self.selectedSubject
        } else if segue.identifier == "ShowGenerationScreen", let generationVC = segue.destination as? GenerationViewController, let items = sender as? [Any] {
            generationVC.sourceItems = items
            generationVC.parentSubjectName = selectedSubject
            selectionCancelTapped()
        }
    }
}
