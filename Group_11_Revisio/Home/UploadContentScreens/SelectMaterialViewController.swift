import UIKit

class SelectMaterialViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties
    var filesToSave: [URL] = [] // The files passed from Upload screen
    var folders: [String] = []
    var selectedFolder: String?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavBar()
        
        // Listen for folder changes
        NotificationCenter.default.addObserver(self, selector: #selector(loadFoldersFromDataStore), name: .didUpdateStudyFolders, object: nil)
        
        loadFoldersFromDataStore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFoldersFromDataStore()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddFolder))
    }
    
    // MARK: - Fetch Logic
    @objc func loadFoldersFromDataStore() {
        let currentFolders = DataManager.shared.savedMaterials.keys.sorted()
        
        if currentFolders.isEmpty {
            self.folders = ["General Study"]
        } else {
            self.folders = currentFolders
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    @objc private func didTapAddFolder() {
        let alert = UIAlertController(title: "New Folder", message: "Enter a name for this subject.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Subject Name (e.g. Calculus)"
            tf.autocapitalizationType = .words
        }
        
        let addAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text,
                  !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            
            DataManager.shared.addFolder(name: name)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    @IBAction func doneTap(_ sender: UIButton) {
        guard selectedFolder != nil else {
            let alert = UIAlertController(title: "Selection Required", message: "Please select a folder to proceed.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        performSegue(withIdentifier: "showGeneration", sender: self)
    }

    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "FolderCell")
        
        var content = cell.defaultContentConfiguration()
        content.text = folders[indexPath.row]
        content.image = UIImage(systemName: "folder")
        content.imageProperties.tintColor = .systemBlue
        cell.contentConfiguration = content
        
        let folderName = folders[indexPath.row]
        let isSelected = (folderName == selectedFolder)
        
        let iconName = isSelected ? "checkmark.circle.fill" : "circle"
        let iconColor = isSelected ? UIColor.systemBlue : UIColor.systemGray3
        
        let iconImageView = UIImageView(image: UIImage(systemName: iconName))
        iconImageView.tintColor = iconColor
        cell.accessoryView = iconImageView
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedFolder = folders[indexPath.row]
        tableView.reloadData()
    }

    // MARK: - Navigation (✅ FIXED SEGUE LOGIC)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGeneration" {
            
            let folder = selectedFolder ?? "General Study"
            
            // 1. Check for Home Tab Generator
            if let homeDest = segue.destination as? GenerateHomeViewController {
                homeDest.contextSubjectTitle = folder
                homeDest.inputSourceData = filesToSave
            }
            // 2. ✅ Check for Study Tab Generator (This was missing!)
            else if let studyDest = segue.destination as? GenerationViewController {
                studyDest.parentSubjectName = folder
                studyDest.sourceItems = filesToSave // Pass the URLs here
            }
        }
    }
}
