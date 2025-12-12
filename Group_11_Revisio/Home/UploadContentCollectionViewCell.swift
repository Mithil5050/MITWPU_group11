// UploadContentCollectionViewCell.swift

import UIKit

// Reuse ID for the inner Table View cell
let innerUploadCellID = "InnerUploadCellID"

class UploadContentCollectionViewCell: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource {

    // You must connect this outlet to the Table View in your XIB/Storyboard
    @IBOutlet weak var tableView: UITableView!
    
    // Closure to notify the owning view controller when the Add button is tapped
    var onAddTapped: (() -> Void)?
    
    // Data source for the internal table view
    var uploadData: [ContentItem] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.backgroundColor = .systemRed
        tableView.layer.cornerRadius = 12.0
        // 1. Setup Table View delegates
        tableView.delegate = self
        tableView.dataSource = self
        
        // 2. Register the cell for the inner table (assuming a standard UITableViewCell for the file rows)
        // If you are using a custom XIB/Cell for the file row, change the name and register that.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: innerUploadCellID)
        
        // 3. Optional: Set a fixed, non-scrolling height for the inner table
        // This is crucial to prevent nested scrolling issues.
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
    }
    
    @IBAction func AddButtonTapped(_ sender: UIButton) {
        // Notify the owning view controller instead of trying to performSegue here
        onAddTapped?()
        
    }
    
    // Call this from HomeViewController to pass the data
    func configure(with items: [ContentItem]) {
        // FIX: Filter out the AddButton item so the Table View only displays files.
        self.uploadData = items.filter { $0.itemType != "AddButton" }
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of files you want to display in this group
        return uploadData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: innerUploadCellID, for: indexPath)
        let item = uploadData[indexPath.row]
        
        // Configure the basic cell for the file display
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        // If iconName is empty, use a default system icon ("doc.fill")
        content.image = UIImage(systemName: item.iconName.isEmpty ? "doc.fill" : item.iconName)
        
        // Use a modern, streamlined style for the cell content
//        content.textProperties.font = UIFont.preferredFont(forTextStyle: .title3)
        content.textProperties.font = UIFont.systemFont(ofSize: 17)
        content.textProperties.color = .label
        content.imageProperties.tintColor = .systemBlue
        cell.backgroundColor = UIColor(hex: "F5F5F5")
        
        cell.contentConfiguration = content
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("File tapped inside collection view cell: \(uploadData[indexPath.row].title)")
        // Typically, you would use a Delegate or Closure here to notify HomeViewController
    }
}
