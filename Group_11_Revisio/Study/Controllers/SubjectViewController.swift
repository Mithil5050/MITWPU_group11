//
//  SubjectViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import UIKit

class SubjectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   

    var doneSelectionButton: UIBarButtonItem!
    var cancelSelectionButton: UIBarButtonItem!
   
    var originalRightBarButtonItems: [UIBarButtonItem]?

    var activeSegmentTitle: String {
        return materialsSegmentedControl.titleForSegment(at: materialsSegmentedControl.selectedSegmentIndex) ?? "Materials"
    }

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
            primaryAction.image = UIImage(systemName: "wand.and.stars")
            primaryAction.tintColor = .systemBlue
        } else {
            primaryAction = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(shareAction))
            primaryAction.image = UIImage(systemName: "square.and.arrow.up")
            primaryAction.tintColor = .systemBlue
        }

        let deleteButton = UIBarButtonItem(title: "Delete", image: UIImage(systemName: "trash"), target: self, action: #selector(deleteSelectionAction))
        deleteButton.tintColor = .systemRed

        let moveButton = UIBarButtonItem(title: "Move", image: UIImage(systemName: "arrowshape.turn.up.right"), target: self, action: #selector(moveSelectionAction))

        let buttons = [deleteButton, moveButton, primaryAction]
        for button in buttons {
            button.isEnabled = isSelectionActive
        }
        
        // Restored to the original 3 items
        self.toolbarItems = [deleteButton, flexibleSpace, moveButton, flexibleSpace, primaryAction]
        
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
    @objc func generateAction() {
        guard let selectedPaths = topicsTableView.indexPathsForSelectedRows, !selectedPaths.isEmpty else { return }

        // Map closure to unwrap StudyItems back into raw objects for the Generation screen
        let selectedRawItems: [Any] = selectedPaths.compactMap { indexPath in
            let item = filteredContent[indexPath.row]
            if let studyItem = item as? StudyItem {
                switch studyItem {
                case .topic(let topic): return topic
                case .source(let source): return source
                }
            }
            return nil
        }
        
        performSegue(withIdentifier: "ShowGenerationScreen", sender: selectedRawItems)
    }
    @objc func shareAction() {
        print("Action: Sharing selected materials.")
    }
    @objc func moveSelectionAction() {
        guard let selectedPaths = topicsTableView.indexPathsForSelectedRows, !selectedPaths.isEmpty else { return }
        
        let selectedRawItems: [Any] = selectedPaths.compactMap { indexPath in
            let item = filteredContent[indexPath.row]
            if let studyItem = item as? StudyItem {
                switch studyItem {
                case .topic(let topic): return topic
                case .source(let source): return source
                }
            }
            return nil
        }

        let allSubjects = DataManager.shared.savedMaterials.keys.sorted()
        let otherSubjects = allSubjects.filter { $0 != selectedSubject }

        if otherSubjects.isEmpty {
            let alert = UIAlertController(title: "No Destination", message: "Create another subject folder first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let moveAlert = UIAlertController(title: "Move \(selectedRawItems.count) Items", message: "Select destination subject", preferredStyle: .actionSheet)

        for subject in otherSubjects {
            moveAlert.addAction(UIAlertAction(title: subject, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                DataManager.shared.moveItems(
                    items: selectedRawItems,
                    from: self.selectedSubject ?? "",
                    to: subject
                )
                
                self.selectionDoneTapped()
                
                if let current = self.selectedSubject {
                    self.loadContentForSubject(current, segmentIndex: self.materialsSegmentedControl.selectedSegmentIndex)
                }
            })
        }

        moveAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Even for iPhone, this is the safest way to present to avoid 'Unsatisfied Constraints' warnings in the console
        if let popover = moveAlert.popoverPresentationController {
            popover.barButtonItem = self.toolbarItems?[2]
        }

        present(moveAlert, animated: true)
    }
    @objc func deleteSelectionAction() {
        guard let selectedPaths = topicsTableView.indexPathsForSelectedRows, !selectedPaths.isEmpty else { return }

        // Use compactMap (a closure) to unwrap StudyItems into raw Topic/Source objects
        let selectedRawItems: [Any] = selectedPaths.compactMap { indexPath in
            let item = filteredContent[indexPath.row]
            if let studyItem = item as? StudyItem {
                switch studyItem {
                case .topic(let topic): return topic
                case .source(let source): return source
                }
            }
            return nil
        }
     
        let alert = UIAlertController(
            title: "Delete Selected Items?",
            message: "Are you sure you want to permanently delete \(selectedRawItems.count) items?",
            preferredStyle: .alert
        )

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Pass the unwrapped items to the DataManager
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

    @objc func moveAllContent() {
        print("Action: Initiating Move All Content operation for subject \(selectedSubject ?? "current").")
    }

    @objc func deleteAllContent() {
        print("Action: Initiating Delete All Content operation for subject \(selectedSubject ?? "current").")
    }
    
    
    var selectedSubject: String?
   
    var currentContent: [Any] = []
    var currentFilterType: String = "All"
    var filteredContent: [Any] = []
    
    
    private let filterOptions: [String] = ["All", "Flashcards", "Quiz", "Cheatsheet", "Notes"]
    
    
    @IBOutlet var materialsSegmentedControl: UISegmentedControl!
    @IBOutlet var topicsTableView: UITableView!
    
   
    @IBOutlet var filterButton: UIBarButtonItem!
    
    @IBOutlet var optionsButton: UIBarButtonItem!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.toolbarItems = []
      
        
        let buttonColor: UIColor = .label
        doneSelectionButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(selectionDoneTapped))
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
//        
//        topicsTableView.layer.cornerRadius = 12.0
//        topicsTableView.clipsToBounds = true
        topicsTableView.backgroundColor = .systemBackground

        
        view.backgroundColor = .systemBackground
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        materialsSegmentedControl.selectedSegmentIndex = 0
        
       
        self.tabBarController?.tabBar.isHidden = false
        
       
        self.navigationController?.setToolbarHidden(true, animated: animated)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataUpdate), name: .didUpdateStudyMaterials, object: nil)
        
        
        if let subject = selectedSubject {
            loadContentForSubject(subject, segmentIndex: materialsSegmentedControl.selectedSegmentIndex)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       
        NotificationCenter.default.removeObserver(self, name: .didUpdateStudyMaterials, object: nil)
    }
    
    @IBAction func segmentControlTapped(_ sender: Any) {
        if let subject = selectedSubject {
                    
            loadContentForSubject(subject, segmentIndex: (sender as AnyObject).selectedSegmentIndex)
                }
    }
    
    @objc func handleDataUpdate() {
       
        if let subject = selectedSubject {
            loadContentForSubject(subject, segmentIndex: materialsSegmentedControl.selectedSegmentIndex)
        }
    }
    
   

    func exitSelectionMode() {
      
        self.navigationItem.rightBarButtonItems = self.originalRightBarButtonItems
        
       
        self.navigationItem.leftBarButtonItem = nil
        
       
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.tabBarController?.tabBar.isHidden = false
        
      
        self.optionsButton.menu = self.setupOptionsMenu()
    }
    func segmentKey(forIndex index: Int) -> String {
        
        return index == 0 ? DataManager.materialsKey : DataManager.sourcesKey
    }
    
    
    
    func setupTableView() {
        topicsTableView.delegate = self
        topicsTableView.dataSource = self
        
        // 1. Register the XIB correctly
        let nib = UINib(nibName: "MaterialViewCell", bundle: nil)
        topicsTableView.register(nib, forCellReuseIdentifier: "MaterialViewCell")
        
        // 2. Styling for the "Continue Learning" look
        topicsTableView.separatorStyle = .none
        topicsTableView.backgroundColor = .systemBackground // or UIColor.black for true dark mode
        
        // 3. Set the height to 96 (80pt card + 16pt gap)
        // This allows the layoutSubviews in the cell to create the spacing
        topicsTableView.rowHeight = 76
        
        topicsTableView.tableFooterView = UIView()
        topicsTableView.allowsMultipleSelectionDuringEditing = true
        topicsTableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
    }
   
    func setupSearchController() {
        searchController.searchBar.placeholder = "Search in \(selectedSubject ?? "this subject")"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
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
            print("Loaded \(content.count) items for \(key).")
        } else {
            
            self.currentContent = []
            print("Content array is missing for segment: \(key).")
        }
        
        self.currentFilterType = "All" // Reset filter on segment change
        self.applyFilterAndReload()
        // 4. Update the Table View to reflect the new data
        topicsTableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredContent.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 1. Dequeue the MaterialViewCell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MaterialViewCell", for: indexPath) as? MaterialViewCell else {
            return UITableViewCell()
        }
        
        // 2. Get the StudyItem (Topic or Source)
        let contentItem = filteredContent[indexPath.row]
        
        if let studyItem = contentItem as? StudyItem {
            // 3. Use the logic replicated from LearningTaskCell
            cell.configure(with: studyItem)
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // This ensures that even when the cell is reused, the 'Card' look stays clean
        cell.backgroundColor = .clear
    }
   
   
    
    func getMaterialVisuals(for type: String) -> (symbolName: String, color: UIColor) {
        switch type {
        case "Flashcards":
            return (symbolName: "rectangle.on.rectangle.angled", color: .flashcardColor)
        case "Quiz":
            return (symbolName: "timer", color: .quizColor)
        case "Cheatsheet":
            
            return (symbolName: "list.bullet.clipboard", color: .cheatsheetColor)
        case "Notes":
           
            return (symbolName: "book.pages", color: .noteColor)
        default:
            return (symbolName: "folder.fill", color: .systemGray)
        }
    }
    
    func getSourceVisuals(for type: String) -> (symbolName: String, color: UIColor) {
        switch type {
        case "PDF": return (symbolName: "doc.fill", color: .systemRed)
        case "Link": return (symbolName: "link", color: .systemBlue)
        case "Video": return (symbolName: "video.fill", color: .systemGreen)
        default: return (symbolName: "questionmark.document.fill", color: .systemGray)
        }
    }
      
    // MARK: - UITableViewDelegate
    
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateToolbarForSelection()
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            
            guard let studyItem = filteredContent[indexPath.row] as? StudyItem else { return }
            
            switch studyItem {
            case .topic(let topic):
                let viewableTypes = ["Notes", "Cheatsheet"]
                
                if viewableTypes.contains(topic.materialType) {
                    performSegue(withIdentifier: "ShowMaterialDetail", sender: topic)
                } else if topic.materialType == "Quiz" {
                    performSegue(withIdentifier: "ShowInstructionScreen", sender: topic)
                } else if topic.materialType == "Flashcards" {
                   
                    performSegue(withIdentifier: "openFlashcards", sender: topic)
                } else {
                    // Fallback for types you haven't built yet
                    let alert = UIAlertController(title: "Coming Soon", message: "View for \(topic.materialType) is coming soon.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
                
            case .source(let source):
                print("Opening source: \(source.name)")
            }
        }
    }
    

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing {
            
            print("Item at \(indexPath.row) deselected.")
           
            updateToolbarForSelection()
        }
    }
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 1
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
        
       
        let menu = UIMenu(title: "Filter by Type", children: actions)
        filterButton.menu = menu 
        
        
    }
   
    func applyFilterAndReload() {
        let contentToFilter = currentContent
        
        if currentFilterType == "All" {
            filteredContent = contentToFilter
        } else {
            // Advanced Closure using 'filter'
            filteredContent = contentToFilter.filter { item in
                guard let studyItem = item as? StudyItem else { return false }
                
                switch studyItem {
                case .topic(let topic):
                    // The actual filtering logic
                    return topic.materialType == currentFilterType
                case .source:
                    // Sources don't match material types like "Quiz" or "Notes"
                    return false
                }
            }
        }
        
        topicsTableView.reloadData()
    }
   

   

    func setupOptionsMenu() -> UIMenu {
        let isSelectModeActive = topicsTableView.isEditing
        
        // Changing the image to be static "checkmark.circle" so it never fills
        let selectAction = UIAction(title: isSelectModeActive ? "Done" : "Select",
                                    image: UIImage(systemName: "checkmark.circle"),
                                    handler: { [weak self] action in
            guard let self = self else { return }
            
            if self.topicsTableView.isEditing {
                self.selectionDoneTapped()
            } else {
                self.topicsTableView.setEditing(true, animated: true)
                self.topicsTableView.allowsMultipleSelectionDuringEditing = true
                
                self.navigationItem.rightBarButtonItems = [self.doneSelectionButton]
                self.navigationItem.leftBarButtonItem = self.cancelSelectionButton
                
                self.updateToolbarForSelection()
                self.tabBarController?.tabBar.isHidden = true
            }
            
            DispatchQueue.main.async {
                self.optionsButton.menu = self.setupOptionsMenu()
            }
        })
        
        selectAction.state = .off
        
        let renameAction = UIAction(title: "Rename Subject", image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.renameCurrentSubject()
        }
        
        let moveAllAction = UIAction(title: "Move All Content", image: UIImage(systemName: "arrow.turn.forward"), handler: { [weak self] _ in
            self?.moveAllContent()
        })
        
        let deleteAllAction = UIAction(title: "Delete All Content", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { [weak self] _ in
            self?.deleteAllContent()
        })
        
        let globalActionsMenu = UIMenu(title: "Management", children: [moveAllAction, deleteAllAction])
        
        let viewAsAction = UIAction(title: "View as", image: UIImage(systemName: "list.bullet.indent"), handler: { _ in
            print("Action: View as triggered.")
        })
        
        let sortByAction = UIAction(title: "Sort By", image: UIImage(systemName: "arrow.up.arrow.down"), handler: { _ in
            print("Action: Sort By triggered.")
        })
        
        let menu = UIMenu(title: "Option", children: [
            selectAction,
            renameAction,
            globalActionsMenu,
            UIMenu(title: "Display Options", options: .displayInline, children: [viewAsAction, sortByAction])
        ])
        
        return menu
    }
   
    @objc func renameCurrentSubject() {
        guard let oldName = selectedSubject else { return }
        
        presentRenameAlert(for: oldName) { [weak self] newName in
            guard let self = self else { return }
            
            
            DataManager.shared.renameSubject(oldName: oldName, newName: newName)
            
            self.selectedSubject = newName
            self.title = newName
            self.setupSearchController()
            
            self.loadContentForSubject(newName, segmentIndex: self.materialsSegmentedControl.selectedSegmentIndex)
            NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        }
    }
    func renameMaterialAction(for item: Any) {
        let currentName: String
        if let topic = item as? Topic { currentName = topic.name }
        else if let source = item as? Source { currentName = source.name }
        else { return }

        let alert = UIAlertController(title: "Rename Material", message: "Enter a new name", preferredStyle: .alert)
        alert.addTextField { $0.text = currentName }

        let rename = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            
            DataManager.shared.renameMaterial(subjectName: self.selectedSubject ?? "", item: item, newName: newName)
            
            if let subject = self.selectedSubject {
                self.loadContentForSubject(subject, segmentIndex: self.materialsSegmentedControl.selectedSegmentIndex)
            }
        }

        alert.addAction(rename)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc func handleRenameSelection() {
        guard let selectedPaths = topicsTableView.indexPathsForSelectedRows, selectedPaths.count == 1 else { return }
        let item = filteredContent[selectedPaths[0].row]
        
        if let studyItem = item as? StudyItem {
            switch studyItem {
            case .topic(let topic): renameMaterialAction(for: topic)
            case .source(let source): renameMaterialAction(for: source)
            }
        }
    }
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = filteredContent[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let rename = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in
                if let studyItem = item as? StudyItem {
                    switch studyItem {
                    case .topic(let topic): self?.renameMaterialAction(for: topic)
                    case .source(let source): self?.renameMaterialAction(for: source)
                    }
                }
            }
            
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                // Trigger your single delete logic here if you have one
                self?.deleteSelectionAction()
            }
            
            return UIMenu(title: "", children: [rename, delete])
        }
    }

    

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        return .none
    }

    // Helper function to present the menu manually via target-action
    @objc func showOptionsMenu() {
        // Rebuild the menu to ensure checkmarks are updated
        let menu = setupOptionsMenu()
        
        // Manually present the menu using the UIBarButton's built-in presentation API
        optionsButton.menu = menu
        
        
    }
    // SubjectViewController.swift (Add this method)

    // SubjectViewController.swift (Selection Handlers)

    @objc func selectionDoneTapped() {
        // Ends selection mode, keeping items selected for the toolbar action
        topicsTableView.isEditing = false
        exitSelectionMode()
        print("Action: Selection Done.")
    }

    @objc func selectionCancelTapped() {
        // 1. Clear selections visually
        if let selected = topicsTableView.indexPathsForSelectedRows {
            for indexPath in selected {
                topicsTableView.deselectRow(at: indexPath, animated: false)
            }
        }
        
        // 2. Clear editing state
        topicsTableView.setEditing(false, animated: true) // Use setEditing(false, animated: true)
        
        // 3. Restore UI (hides toolbar, restores nav bar buttons)
        exitSelectionMode()
        print("Action: Selection Cancelled.")
        
        
        topicsTableView.reloadData()
    }

   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        var finalTopic: Topic?
        
        if let topic = sender as? Topic {
            finalTopic = topic
        } else if let studyItem = sender as? StudyItem {
            if case .topic(let topic) = studyItem {
                finalTopic = topic
            }
        }

        // --- YOUR EXISTING SEGUES ---
        if segue.identifier == "ShowMaterialDetail" {
            if let detailVC = segue.destination as? MaterialDetailViewController, let topic = finalTopic {
                detailVC.materialName = topic.name
                detailVC.contentData = topic
                detailVC.parentSubjectName = selectedSubject
            }
        } else if segue.identifier == "ShowInstructionScreen" {
            if let instructionVC = segue.destination as? InstructionViewController, let topic = finalTopic {
                instructionVC.quizTopic = topic
                instructionVC.parentSubjectName = selectedSubject
            }
        }
        
        else if segue.identifier == "openFlashcards" {
            if let flashVC = segue.destination as? FlashcardsViewController, let topic = finalTopic {
                // 1. Pass the topic data (questions/answers)
                flashVC.currentTopic = topic
                
                // 2. Pass the folder name (Required for SAVING new cards to JSON)
                flashVC.parentSubjectName = self.selectedSubject
            }
        }
        // --- REST OF YOUR CODE ---
        else if segue.identifier == "ShowGenerationScreen" {
            if let generationVC = segue.destination as? GenerationViewController, let items = sender as? [Any] {
                generationVC.sourceItems = items
                generationVC.parentSubjectName = selectedSubject
                selectionCancelTapped()
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

