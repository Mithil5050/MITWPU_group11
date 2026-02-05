import UIKit

class SelectMaterialViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties
    // Accepts an Array of URLs to handle multiple files
    var filesToSave: [URL] = []
    
    // Will be populated dynamically from DataManager
    var folders: [String] = []
    
    var selectedFolder: String?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavBar()
        
        // Listen for folder changes (Syncs with Study Tab logic)
        NotificationCenter.default.addObserver(self, selector: #selector(loadFoldersFromDataStore), name: .didUpdateStudyFolders, object: nil)
        
        loadFoldersFromDataStore()
    }
    
    // Reload data every time view appears to ensure sync with Study Tab
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
        // Add a "+" button so user can create a folder right here
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddFolder))
    }
    
    // MARK: - Fetch Logic
    @objc func loadFoldersFromDataStore() {
        // Get keys (folder names) directly from the shared DataManager
        let currentFolders = DataManager.shared.savedMaterials.keys.sorted()
        
        if currentFolders.isEmpty {
            // Fallback if app is brand new and empty
            self.folders = ["General Study"]
        } else {
            self.folders = currentFolders
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    // ✅ NEW: Add Folder Logic (Same as Study Tab)
    @objc private func didTapAddFolder() {
        let alert = UIAlertController(title: "New Folder", message: "Enter a name for this subject.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Subject Name (e.g. Calculus)"
            tf.autocapitalizationType = .words
        }
        
        let addAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text,
                  !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            
            // This calls DataManager, which saves to disk AND posts the notification
            // The notification triggers 'loadFoldersFromDataStore', updating the table automatically.
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
        
        // ✅ OLD FLOW RESTORED: Navigate to Generation Screen
        performSegue(withIdentifier: "showGeneration", sender: self)
    }

    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "FolderCell")
        
        // 1. Configure Content
        var content = cell.defaultContentConfiguration()
        content.text = folders[indexPath.row]
        content.image = UIImage(systemName: "folder")
        content.imageProperties.tintColor = .systemBlue
        cell.contentConfiguration = content
        
        // 2. Configure Selection
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

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGeneration" {
            if let destVC = segue.destination as? GenerateHomeViewController {
                if let folder = selectedFolder {
                    destVC.contextSubjectTitle = folder
                    // Pass the files to the generation screen
                    destVC.inputSourceData = filesToSave
                }
            }
        }
    }
}
