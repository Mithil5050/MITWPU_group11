//
//  SubjectViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import UIKit

class SubjectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // SubjectViewController.swift (Inside the class)
    // SubjectViewController.swift (Inside the class)

    var doneSelectionButton: UIBarButtonItem!
    var cancelSelectionButton: UIBarButtonItem!
    // Store the original right bar button items (Filter and Options)
    var originalRightBarButtonItems: [UIBarButtonItem]?

    var activeSegmentTitle: String {
        return materialsSegmentedControl.titleForSegment(at: materialsSegmentedControl.selectedSegmentIndex) ?? "Materials"
    }

    func updateToolbarForSelection() {
        
        // Check selection state
        let selectedCount = topicsTableView.indexPathsForSelectedRows?.count ?? 0
        let isSelectionActive = selectedCount > 0
        
        // --- 1. Tool Visibility Check ---
        // If we are NOT in editing mode, always ensure the toolbar is hidden.
        if !topicsTableView.isEditing {
            self.navigationController?.setToolbarHidden(true, animated: true)
            return
        }
        
        // --- 2. Toolbar Button Definitions (SF Symbols) ---
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Primary Action (Dynamic Share/Generate)
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

        // General Actions (Delete/Move)
        let deleteButton = UIBarButtonItem(title: "Delete", image: UIImage(systemName: "trash"), target: self, action: #selector(deleteSelectionAction))
        deleteButton.tintColor = .systemRed

        let moveButton = UIBarButtonItem(title: "Move", image: UIImage(systemName: "arrowshape.turn.up.right"), target: self, action: #selector(moveSelectionAction))

        // --- 3. CRITICAL FIX: Disabling Logic ---
        let buttons = [deleteButton, moveButton, primaryAction]
        for button in buttons {
            // Disable all buttons if isSelectionActive is false (i.e., selection count is zero)
            button.isEnabled = isSelectionActive
        }
        
        // 4. Set Toolbar Items and Show
        self.toolbarItems = [deleteButton, flexibleSpace, moveButton, flexibleSpace, primaryAction]
        
        // Since we are inside the isEditing block, ensure the toolbar is shown.
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
    @objc func generateAction() {
        print("Action: Generating from selected sources.")
    }
    @objc func shareAction() {
        print("Action: Sharing selected materials.")
    }
    @objc func moveSelectionAction() {
        print("Action: Moving selected items.")
    }
    @objc func deleteSelectionAction() {
        print("Action: Deleting selected items.")
    }

    @objc func moveAllContent() {
        print("Action: Initiating Move All Content operation for subject \(selectedSubject ?? "current").")
    }

    @objc func deleteAllContent() {
        print("Action: Initiating Delete All Content operation for subject \(selectedSubject ?? "current").")
    }
    
    // This property is set by StudyFolderViewController in prepare(for:sender:)
    var selectedSubject: String?
   
    var currentContent: [Any] = []
    var currentFilterType: String = "All"
    var filteredContent: [Any] = []
    
    // Define available filter options for Materials
    // These should match Topic.materialType values plus "All"
    private let filterOptions: [String] = ["All", "Flashcards", "Quiz", "Cheatsheet", "Notes"]
    // SubjectViewController.swift (Inside the class body)

    
    @IBOutlet var materialsSegmentedControl: UISegmentedControl!
    @IBOutlet var topicsTableView: UITableView!
    
    // If this is connected in Interface Builder, we will ignore its primary-action property
    // and replace it with a custom UIButton-backed bar button item to support iOS 14+.
    @IBOutlet var filterButton: UIBarButtonItem!
    
    @IBOutlet var optionsButton: UIBarButtonItem!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // --- CRITICAL FIX: Ensure Toolbar Items Array is EMPTY at startup ---
        self.toolbarItems = []
        // --- END CRITICAL FIX ---
        
        
        let buttonColor: UIColor = .label // Use .label for dynamic black/white contrast (best practice)
        
        doneSelectionButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(selectionDoneTapped))
        doneSelectionButton.tintColor = buttonColor // Set color
        
        cancelSelectionButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(selectionCancelTapped))
        cancelSelectionButton.tintColor = buttonColor // Set color
        
        if let selectedSubject {
            title = selectedSubject
            setupTableView()
            setupSearchController()
            loadContentForSubject(selectedSubject, segmentIndex: 0)
            setupFilterMenu()
            optionsButton.menu = setupOptionsMenu()
            
            // Store the initial right bar buttons (Filter and Options)
            self.originalRightBarButtonItems = self.navigationItem.rightBarButtonItems
        }
        
        topicsTableView.layer.cornerRadius = 12.0
        topicsTableView.clipsToBounds = true
        topicsTableView.backgroundColor = .systemBackground

        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reset segmented control on screen entry
        materialsSegmentedControl.selectedSegmentIndex = 0
        
        // Ensure the Tab Bar is visible when the view appears normally
        self.tabBarController?.tabBar.isHidden = false
        
        // Ensure the Navigation Toolbar is HIDDEN by default
        self.navigationController?.setToolbarHidden(true, animated: animated)
        
        // Observer is added here to catch data updates/renames from other views
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataUpdate), name: .didUpdateStudyMaterials, object: nil)
        
        // Initial data load uses the current segment selection (ensures content is reloaded)
        if let subject = selectedSubject {
            loadContentForSubject(subject, segmentIndex: materialsSegmentedControl.selectedSegmentIndex)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Always remove the observer when the view disappears
        NotificationCenter.default.removeObserver(self, name: .didUpdateStudyMaterials, object: nil)
    }
    
    @IBAction func segmentControlTapped(_ sender: Any) {
        if let subject = selectedSubject {
                    // Load content using the index of the newly tapped segment
            loadContentForSubject(subject, segmentIndex: (sender as AnyObject).selectedSegmentIndex)
                }
    }
    
    @objc func handleDataUpdate() {
        // Reload data if the current subject has updated content, using the active segment.
        // This is crucial for syncing the view if the subject's contents change
        // or if the subject itself was renamed (which fixes the name persistence issue).
        if let subject = selectedSubject {
            loadContentForSubject(subject, segmentIndex: materialsSegmentedControl.selectedSegmentIndex)
        }
    }
    // SubjectViewController.swift (Selection Handlers)


    func exitSelectionMode() {
        // 1. Restore the original navigation bar items (Filter and Options)
        self.navigationItem.rightBarButtonItems = self.originalRightBarButtonItems
        
        // 2. Restore system back button by setting leftBarButtonItem to nil
        self.navigationItem.leftBarButtonItem = nil
        
        // 3. Hide the toolbar and unhide the tab bar
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.tabBarController?.tabBar.isHidden = false
        
        // 4. Rebuild the options menu to update the 'Select' checkmark state
        self.optionsButton.menu = self.setupOptionsMenu()
    }
    func segmentKey(forIndex index: Int) -> String {
        // Maps index 0 to "Materials" and index 1 to "Sources"
        // Currently unused because DataManager only stores materials.
        return index == 0 ? DataManager.materialsKey : DataManager.sourcesKey
    }
    // SubjectViewController.swift (Inside the class)

    
    
    func setupTableView() {
        // Assign protocols
        topicsTableView.delegate = self
        topicsTableView.dataSource = self
        
        // Hides cell separators for clean card design
        topicsTableView.separatorStyle = .none
        topicsTableView.tableFooterView = UIView()
        topicsTableView.allowsMultipleSelectionDuringEditing = true
        
        // If using a nib for TopicCardCell, uncomment and ensure nib name matches
        // let nib = UINib(nibName: "TopicCardCell", bundle: nil)
        // topicsTableView.register(nib, forCellReuseIdentifier: "TopicCardCell")
        
        // If using a storyboard prototype cell, ensure the identifier is set to "TopicCardCellID"
    }
    // SubjectViewController.swift (Inside the class)

    // SubjectViewController.swift (Inside viewDidLayoutSubviews)

//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//        let toolbarHeight = self.navigationController?.toolbar.frame.height ?? 0
//        let safeAreaBottom = view.safeAreaInsets.bottom
//        
//        // Calculation: Add Toolbar height to the system's safe area clearance
//        let requiredInset = toolbarHeight + safeAreaBottom
//        
//        let finalInset = UIEdgeInsets(top: 0, left: 0, bottom: requiredInset, right: 0)
//        
//        if topicsTableView.contentInset != finalInset {
//            topicsTableView.contentInset = finalInset
//            topicsTableView.scrollIndicatorInsets = finalInset
//        }
//    }
    func setupSearchController() {
        searchController.searchBar.placeholder = "Search in \(selectedSubject ?? "this subject")"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    func loadContentForSubject(_ subject: String, segmentIndex: Int) {
        // 1. Determine which segment is selected (e.g., "Materials" or "Sources")
        let key = segmentKey(forIndex: segmentIndex)
        
        // 2. Access the per-subject data structure
        guard let subjectDict = DataManager.shared.savedMaterials[subject] else {
            self.currentContent = []
            topicsTableView.reloadData()
            return
        }
        
        // 3. Get the specific content array based on the segment key
        // The content is retrieved as [Any] since the DataManager stores both Topic and Source here.
        if let content = subjectDict[key] {
            self.currentContent = content
            print("Loaded \(content.count) items for \(key).")
        } else {
            // This handles cases where the segment key exists in the segmented control
            // but is missing in the DataManager for this subject.
            self.currentContent = []
            print("Content array is missing for segment: \(key).")
        }
        // After self.currentContent = content is set in loadContentForSubject:
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TopicCardCell", for: indexPath) as? TopicCardCell else {
            return UITableViewCell()
        }
        
        // CRITICAL CHANGE: Access the item from the filteredContent array.
        // This array holds the result of the filtering logic.
        let contentItem = filteredContent[indexPath.row]
        
        // Type checking logic remains the same, but uses contentItem from the filtered array.
        if let topic = contentItem as? Topic {
            // CASE 1: MATERIALS (Topic objects)
            let visuals = getMaterialVisuals(for: topic.materialType)
            let separator = " • "
            
            cell.titleLabel.text = topic.name
            cell.subtitleLabel.text = topic.materialType + separator + "Last Accessed: \(topic.lastAccessed)"
            cell.iconImageView.image = UIImage(systemName: visuals.symbolName)
            cell.iconImageView.tintColor = visuals.color
            
        } else if let source = contentItem as? Source {
            // CASE 2: SOURCES (Source objects)
            let visuals = getSourceVisuals(for: source.fileType)
            
            cell.titleLabel.text = source.name
            cell.subtitleLabel.text = "\(source.fileType) • \(source.size)"
            cell.iconImageView.image = UIImage(systemName: visuals.symbolName)
            cell.iconImageView.tintColor = visuals.color
            
        } else {
            // Fallback for unknown type
            cell.titleLabel.text = "Error: Unknown Content"
            cell.subtitleLabel.text = ""
            cell.iconImageView.image = UIImage(systemName: "xmark.octagon.fill")
        }
        
        return cell
    }
    // SubjectViewController.swift (Inside the class or extension)

   
    
    func getMaterialVisuals(for type: String) -> (symbolName: String, color: UIColor) {
        switch type {
        case "Flashcards":
            return (symbolName: "rectangle.on.rectangle.angled", color: .flashcardColor)
        case "Quiz":
            return (symbolName: "timer", color: .quizColor)
        case "Cheatsheet":
            // Uses the color with 50% opacity built into the static property
            return (symbolName: "list.bullet.clipboard", color: .cheatsheetColor)
        case "Notes":
            // Uses the color with 75% opacity built into the static property
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
    
    // SubjectViewController.swift (Inside the class or extension)

    // SubjectViewController.swift (Inside the class or extension)

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     
        // When in editing mode, we must NOT deselect the row.
        
        if tableView.isEditing {
            // In select mode, allow selection to persist and update toolbar
            print("Item at \(indexPath.row) selected.")
            updateToolbarForSelection()
        } else {
            // In normal mode, deselect and handle detail navigation.
            
            // Ensure the row is deselected immediately in normal mode
            tableView.deselectRow(at: indexPath, animated: true)
            
            let contentItem = filteredContent[indexPath.row]
            
            if let topic = contentItem as? Topic {
                let viewableTypes = ["Notes", "Cheatsheet"] // Only allow these types to navigate

                if viewableTypes.contains(topic.materialType) {
                    performSegue(withIdentifier: "ShowMaterialDetail", sender: topic)
                } else {
                    // Handle Quiz and Flashcards differently
                    print("Action: Opening dedicated view for \(topic.materialType)")
                    let alert = UIAlertController(title: "Feature Coming Soon", message: "A dedicated view for \(topic.materialType) will be available shortly.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing {
            // In select mode, register deselection and refresh toolbar
            print("Item at \(indexPath.row) deselected.")
            // --- ADD THIS LINE ---
            updateToolbarForSelection()
        }
    }
    // SubjectViewController.swift (Inside the class)

    // SubjectViewController.swift (Inside the class)

    func setupFilterMenu() {
        
        let actions: [UIAction] = filterOptions.map { filterName in
            
            let action = UIAction(title: filterName, handler: { [weak self] action in
                guard let self = self else { return }
                
                // 1. Update the filter state
                self.currentFilterType = action.title
                
                // 2. Re-filter and reload the table view
                self.applyFilterAndReload()
                
                // 3. IMPORTANT: Recreate the menu to update the checkmark state
                self.setupFilterMenu()
            })
            
            // Add the checkmark to the currently active filter
            action.state = (filterName == currentFilterType) ? .on : .off
            
            return action
        }
        
        // Assign the UIMenu to the filterButton outlet
        let menu = UIMenu(title: "Filter by Type", children: actions)
        filterButton.menu = menu // This line should resolve the menu attachment
        
        // Remove conflicting line that caused the error.
        // NOTE: On modern iOS, the system often handles menu display automatically
        // when a menu property is assigned to a bar button item.
        
        // Fallback: If the menu doesn't show up on tap, we would use an older target-action
        // to present the menu manually, but try running it with just the .menu assignment first.
    }
    // SubjectViewController.swift (Inside the class)

    func applyFilterAndReload() {
        
        // 1. Start with all content from the currently active segment (Materials OR Sources)
        let contentToFilter = currentContent
        
        if currentFilterType == "All" {
            // If "All" is selected, show everything.
            filteredContent = contentToFilter
        } else {
            // 2. Filter logic
            filteredContent = contentToFilter.filter { item in
                
                // Only apply the filter if the item is a Topic (Sources do not have materialType)
                if let topic = item as? Topic {
                    return topic.materialType == currentFilterType
                }
                
                // If the filter is active but the item is a Source, it's excluded.
                return false
            }
        }
        
        // 3. Reload the table view with the new filtered data
        topicsTableView.reloadData()
        
        // CRITICAL NOTE: If a segment (like Sources) is active, the filter will only show
        // the "All" option effectively, as Source objects are not Topic objects.
    }
    // SubjectViewController.swift (Inside the class)

    // SubjectViewController.swift (Inside the class)

    // SubjectViewController.swift (Inside the class)

    // SubjectViewController.swift (Inside the class)

    // SubjectViewController.swift (Inside the class)
    // SubjectViewController.swift (Inside the class, replace the current placeholders if they exist)

   

    func setupOptionsMenu() -> UIMenu {
        
        let isSelectModeActive = topicsTableView.isEditing
        
        let selectAction = UIAction(title: isSelectModeActive ? "Done" : "Select",
                                    image: UIImage(systemName: isSelectModeActive ? "checkmark.circle.fill" : "checkmark.circle"),
                                    handler: { [weak self] action in
            guard let self = self else { return }
            
            let isEditing = self.topicsTableView.isEditing

            if isEditing {
                // If already editing (and tapping 'Done' in the menu), exit selection mode.
                self.selectionDoneTapped()
            } else {
                // ENTERING SELECTION MODE
                self.topicsTableView.isEditing = true
                
              
                self.navigationItem.rightBarButtonItems = [self.doneSelectionButton]
                
                // 2. Left side: Replace Back button with CANCEL button
                self.navigationItem.leftBarButtonItem = self.cancelSelectionButton
                
                self.updateToolbarForSelection()
                self.tabBarController?.tabBar.isHidden = true
            }
            
            // Rebuild menu for state change
            DispatchQueue.main.async {
                self.optionsButton.menu = self.setupOptionsMenu()
            }
        })
        
        selectAction.state = .off
        
        let renameAction = UIAction(title: "Rename Subject", image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.renameCurrentSubject()
        }
        // ... rest of menu actions ...
        
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
    // SubjectViewController.swift (Inside the class)
    // SubjectViewController.swift

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
    // SubjectViewController.swift (Add these two methods)

   
    // SubjectViewController.swift (Inside the class or extension)
    // SubjectViewController.swift (Inside the class or extension)

    

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        // If we are in editing mode, allow the default selection tick style (.insert).
        // Otherwise, suppress it.
        if tableView.isEditing {
            return .insert
        } else {
            return .none
        }
    }

    // Helper function to present the menu manually via target-action
    @objc func showOptionsMenu() {
        // Rebuild the menu to ensure checkmarks are updated
        let menu = setupOptionsMenu()
        
        // Manually present the menu using the UIBarButton's built-in presentation API
        optionsButton.menu = menu
        
        // This is often sufficient to display the menu when tapped
        // If not, iOS 14+ will usually display the assigned menu property upon tap automatically.
        // If you need the select/import actions to be displayed immediately on tap,
        // you must use the Target-Action pattern to simulate the primary action behavior.
        
        // For now, rely on the .menu property assignment in the tapped action
        // which is the simplest reliable way to activate it.
        
        // NOTE: Delete the old setupOptionsMenu() call from viewDidLoad.
        // You only need to call this function inside the @objc showOptionsMenu()
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
        // Discard selection and exit editing mode
        // Clear selections visually
        if let selected = topicsTableView.indexPathsForSelectedRows {
            for indexPath in selected {
                topicsTableView.deselectRow(at: indexPath, animated: false)
            }
        }
        topicsTableView.isEditing = false
        exitSelectionMode()
        print("Action: Selection Cancelled.")
    }

    // NOTE: Your exitSelectionMode() already contains the necessary logic to restore buttons and exit editing.

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowMaterialDetail" {
            if let detailVC = segue.destination as? MaterialDetailViewController,
               let topic = sender as? Topic {
                
                // Pass the Topic data
                detailVC.materialName = topic.name
                detailVC.contentData = topic
                
                
                detailVC.parentSubjectName = selectedSubject
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

