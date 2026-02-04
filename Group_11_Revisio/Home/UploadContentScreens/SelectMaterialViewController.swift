import UIKit

class SelectMaterialViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties
    // Accepts an Array of URLs to handle multiple files
    var filesToSave: [URL] = []
    
    var folders = [
        "Calculus",
        "Data Structures",
        "Big Data",
        "MMA",
        "Swift Fundamentals",
        "Computer Network",
        "General Study"
    ]
    
    var selectedFolder: String?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - Actions
    @IBAction func doneTap(_ sender: UIButton) {
        guard let folder = selectedFolder else {
            let alert = UIAlertController(title: "Selection Required", message: "Please select a folder to proceed.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Loop through ALL files and save them
        if !filesToSave.isEmpty {
            print("💾 Saving \(filesToSave.count) items to \(folder)...")
            for url in filesToSave {
                DataManager.shared.importFile(url: url, subject: folder)
            }
        }
        
        performSegue(withIdentifier: "showGeneration", sender: nil)
    }
    
    @IBAction func addFolderTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Folder", message: "Enter a name for this folder", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Folder Name" }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                self.folders.append(name)
                DataManager.shared.createNewSubjectFolder(name: name)
                self.tableView.reloadData()
            }
        })
        present(alert, animated: true)
    }
    
    // MARK: - Table View Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell") ?? UITableViewCell(style: .default, reuseIdentifier: "FolderCell")
        
        // 1. ✅ RESTORED: Configure Content with Folder Icon
        var content = cell.defaultContentConfiguration()
        content.text = folders[indexPath.row]
        content.image = UIImage(systemName: "folder") // The Folder Icon
        content.imageProperties.tintColor = .systemBlue
        cell.contentConfiguration = content
        
        // 2. Configure Selection (Checkmark vs Circle)
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
                    // Pass the list of files to generation screen if needed
                    destVC.inputSourceData = filesToSave
                }
            }
        }
    }
}
