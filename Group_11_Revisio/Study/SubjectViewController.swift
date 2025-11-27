//
//  SubjectViewController.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import UIKit

class SubjectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // This property is set by StudyFolderViewController in prepare(for:sender:)
    var selectedSubject: String?
   
    var currentContent: [Any] = []
    
    @IBOutlet var materialsSegmentedControl: UISegmentedControl!
    @IBOutlet var topicsTableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the UI using the selected subject if available
        if let selectedSubject {
            title = selectedSubject
            setupTableView()
            setupSearchController()
            loadContentForSubject(selectedSubject, segmentIndex: 0)
        }

        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset segmented control on screen entry
        materialsSegmentedControl.selectedSegmentIndex = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataUpdate), name: .didUpdateStudyMaterials, object: nil)
        
        // Initial data load uses the current segment selection
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
        // Reload data if the current subject has updated content, using the active segment
        if let subject = selectedSubject {
            loadContentForSubject(subject, segmentIndex: materialsSegmentedControl.selectedSegmentIndex)
        }
    }
    func segmentKey(forIndex index: Int) -> String {
        // Maps index 0 to "Materials" and index 1 to "Sources"
        // Currently unused because DataManager only stores materials.
        return index == 0 ? DataManager.materialsKey : DataManager.sourcesKey
    }
    
    func setupTableView() {
        // Assign protocols
        topicsTableView.delegate = self
        topicsTableView.dataSource = self
        
        // Hides cell separators for clean card design
        topicsTableView.separatorStyle = .none
        topicsTableView.tableFooterView = UIView()
        
        // If using a nib for TopicCardCell, uncomment and ensure nib name matches
        // let nib = UINib(nibName: "TopicCardCell", bundle: nil)
        // topicsTableView.register(nib, forCellReuseIdentifier: "TopicCardCell")
        
        // If using a storyboard prototype cell, ensure the identifier is set to "TopicCardCellID"
    }
    
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
        
        // 4. Update the Table View to reflect the new data
        topicsTableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentContent.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TopicCardCell", for: indexPath) as? TopicCardCell else {
                return UITableViewCell()
            }
            
            // --- KEY FIX: Access the content item from the unified array ---
            let contentItem = currentContent[indexPath.row]
            
            // Type checking logic to display content correctly
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Handle topic selection if needed
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
