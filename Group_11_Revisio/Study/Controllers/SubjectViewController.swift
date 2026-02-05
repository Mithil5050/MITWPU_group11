//
//  SubjectViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
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
    private var notificationToken: NSObjectProtocol?
    
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
        
        // If we are in the "Sources" segment, we don't apply filters (show all sources)
        if materialsSegmentedControl.selectedSegmentIndex == 1 {
            filteredContent = contentToFilter
        }
        // Otherwise, if "All" is selected in Materials
        else if currentFilterType == "All" {
            filteredContent = contentToFilter
        }
        // Otherwise, filter by the specific material type (Quiz, Flashcards, etc.)
        else {
            filteredContent = contentToFilter.filter { item in
                guard let studyItem = item as? StudyItem else { return false }
                
                switch studyItem {
                case .topic(let topic):
                    return topic.materialType == currentFilterType
                case .source:
                    return false // Sources don't have a "MaterialType"
                }
            }
        }
        topicsTableView.reloadData()
    }
    
    func segmentKey(forIndex index: Int) -> String {
        return index == 0 ? DataManager.materialsKey : DataManager.sourcesKey
    }
    
    func handleDataUpdate() {
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
        }
        
        let renameAction = UIAction(title: "Rename Subject", image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.renameCurrentSubject()
        }
        
        let moveAllAction = UIAction(title: "Move All Content", image: UIImage(systemName: "arrow.turn.forward")) { [weak self] _ in
            self?.moveAllContent()
        }
        
        let deleteAllAction = UIAction(title: "Delete All Content", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.deleteAllContent()
        }
        
        let menu = UIMenu(title: "Option", children: [
            selectAction,
            renameAction,
            UIMenu(title: "Management", children: [moveAllAction, deleteAllAction]),
            UIMenu(title: "Display Options", options: .displayInline, children: [
                UIAction(title: "View as", image: UIImage(systemName: "list.bullet.indent")) { _ in },
                UIAction(title: "Sort By", image: UIImage(systemName: "arrow.up.arrow.down")) { _ in }
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
        // 1. SELECTION MODE CHECK: If the table is in 'Select' mode, update the toolbar and stop
        if tableView.isEditing {
            updateToolbarForSelection()
            return
        }
        
        // 2. DESELECT: Standard visual behavior for single-tap navigation
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 3. THE CRITICAL CAST: Convert the [Any] item to your [StudyItem] enum
        // This fixes the "Expression pattern" build error
        guard let studyItem = filteredContent[indexPath.row] as? StudyItem else {
            print("DEBUG: Item at \(indexPath.row) is not a StudyItem")
            return
        }
        
        // 4. PATTERN MATCH: Extract the Topic data
        if case .topic(let topic) = studyItem {
            
            // 5. FRESH DATA FETCH: Get the absolute latest version from DataManager
            // to ensure we see the new 'attempts' after a user saves a quiz.
            let latestTopic = DataManager.shared.getTopic(subjectName: self.selectedSubject ?? "", topicName: topic.name) ?? topic
            
            // 6. ROUTING LOGIC
            if latestTopic.materialType == "Quiz" {
                
                // THE GATEKEEPER:
                // If no history exists -> Show Instructions
                // If history exists -> Show History Screen
                if latestTopic.safeAttempts.isEmpty {
                    print("DEBUG: No history found. Showing Instructions for \(latestTopic.name)")
                    performSegue(withIdentifier: "ShowInstructionScreen", sender: latestTopic)
                } else {
                    print("DEBUG: History found. Showing Quiz History for \(latestTopic.name)")
                    performSegue(withIdentifier: "ShowQuizHistory", sender: latestTopic)
                }
                
            } else if latestTopic.materialType == "Flashcards" {
                performSegue(withIdentifier: "openFlashcards", sender: latestTopic)
            } else {
                // Standard Notes or Cheatsheet
                performSegue(withIdentifier: "ShowMaterialDetail", sender: latestTopic)
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
        
        // 1. Primary Action (Generate for Sources, Share for others)
        let primaryAction: UIBarButtonItem
        if activeSegmentTitle == "Sources" {
            primaryAction = UIBarButtonItem(title: "Generate", style: .plain, target: self, action: #selector(generateAction))
            
        } else {
            primaryAction = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(shareAction))
        }
        
        // 2. Delete Action
        let deleteButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteSelectionAction))
        deleteButton.tintColor = .systemRed
        
        // Styling the text
        let textAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
        [deleteButton, primaryAction].forEach {
            $0.isEnabled = isSelectionActive
            $0.setTitleTextAttributes(textAttributes, for: .normal)
        }
        
        // Layout: [Delete] ------------------ [Generate/Share]
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
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }
            
            let item = self.filteredContent[indexPath.row]
            let rawItem = self.unwrapStudyItem(item) // Unwraps the StudyItem enum
            
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

    // MARK: - Logic Helpers for Context Menu

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
                // Moves the single item to the new folder
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
    @IBAction func segmentControlTapped(_ sender: UISegmentedControl) {
        if let subject = selectedSubject {
            // Load data based on the selected segment
            loadContentForSubject(subject, segmentIndex: sender.selectedSegmentIndex)
        }
        
        // HIG: Disable the filter button if we are in the "Sources" tab (index 1)
        if sender.selectedSegmentIndex == 0 {
            filterButton.isEnabled = true
            filterButton.tintColor = .label // Normal color
        } else {
            filterButton.isEnabled = false
            filterButton.tintColor = .systemGray // Visual cue that it's inactive
            self.currentFilterType = "All" // Reset filter type for safety
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
        
        if let studyItem = sender as? StudyItem, case .topic(let topic) = studyItem {
            finalTopic = DataManager.shared.getTopic(subjectName: self.selectedSubject ?? "", topicName: topic.name) ?? topic
        } else if let topic = sender as? Topic {
            finalTopic = DataManager.shared.getTopic(subjectName: self.selectedSubject ?? "", topicName: topic.name) ?? topic
        }
        
        if segue.identifier == "ShowQuizHistory" {
            if let historyVC = segue.destination as? QuizHistoryViewController,
               let topic = finalTopic {
                historyVC.quizTopic = topic
                historyVC.parentSubject = self.selectedSubject
            }
        }
        else if segue.identifier == "ShowMaterialInfo",
                let infoVC = segue.destination as? MaterialInfoViewController,
                let studyItem = sender as? StudyItem {
            
            switch studyItem {
            case .topic(let topic):
                infoVC.materialName = topic.name
                infoVC.materialType = topic.materialType
                infoVC.dateCreated = topic.lastAccessed
                infoVC.sourceName = "Attached Document"
                
                switch topic.materialType {
                case "Quiz":
                    infoVC.iconName = "timer"
                    infoVC.iconColor = .systemGreen
                case "Notes":
                    infoVC.iconName = "book.pages"
                    infoVC.iconColor = .systemOrange
                case "Flashcards":
                    infoVC.iconName = "rectangle.on.rectangle.angled"
                    infoVC.iconColor = .systemBlue
                default:
                    infoVC.iconName = "doc.text.fill"
                    infoVC.iconColor = .systemGray
                }
                
            case .source(let source):
                infoVC.materialName = source.name
                infoVC.materialType = source.fileType
                infoVC.dateCreated = "Added Recently"
                infoVC.iconName = source.fileType == "Video" ? "play.tv.fill" : "link"
                infoVC.iconColor = .systemIndigo
            }
        }
        else if segue.identifier == "ShowMaterialDetail",
                let detailVC = segue.destination as? MaterialDetailViewController,
                let topic = finalTopic {
            detailVC.materialName = topic.name
            detailVC.contentData = topic
            detailVC.parentSubjectName = selectedSubject
        }
        else if segue.identifier == "ShowInstructionScreen",
                let instructionVC = segue.destination as? InstructionViewController,
                let topic = finalTopic {
            instructionVC.quizTopic = topic
            instructionVC.parentSubjectName = selectedSubject
        }
        else if segue.identifier == "openFlashcards",
                let flashVC = segue.destination as? FlashcardsViewController,
                let topic = finalTopic {
            flashVC.currentTopic = topic
            flashVC.parentSubjectName = self.selectedSubject
        }
        else if segue.identifier == "ShowGenerationScreen",
                let generationVC = segue.destination as? GenerationViewController,
                let items = sender as? [Any] {
            generationVC.sourceItems = items
            generationVC.parentSubjectName = selectedSubject
            selectionCancelTapped()
        }
    }
}

