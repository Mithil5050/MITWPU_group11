import UIKit

// Global identifier for the internal table rows
let innerUploadCellID = "InnerUploadCellID"

class UploadContentCollectionViewCell: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Callbacks & Data
    var onAddTapped: (() -> Void)?
    var uploadData: [ContentItem] = []

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAdaptiveUI()
    }
    
    // MARK: - UI Configuration
    private func setupAdaptiveUI() {
        // 1. Define the Master Background Color
        let masterBackground = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                   .secondarySystemBackground :
                   UIColor(hex: "F5F5F5")
        }
        
        // Apply to the TableView
        tableView.backgroundColor = masterBackground
        tableView.backgroundView = nil
        
        // 2. Modern Surface Smoothing
        tableView.layer.cornerRadius = 16.0
        tableView.layer.cornerCurve = .continuous
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: innerUploadCellID)
        
        // 3. Layout Performance
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .separator
        tableView.tableFooterView = UIView() // Clears extra lines at the bottom
    }
    
    @IBAction func AddButtonTapped(_ sender: UIButton) {
        onAddTapped?()
    }
    
    func configure(with items: [ContentItem]) {
        self.uploadData = items.filter { $0.itemType != "AddButton" }
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uploadData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: innerUploadCellID, for: indexPath)
        let item = uploadData[indexPath.row]
        
        // --- UPDATED: THE CELL COLOR FIX ---
        // We set the cell's background to .clear so it doesn't overlap the TableView's F5F5F5.
        // If it still looks white, we also force the contentView to .clear.
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        
        // Modern Configuration Pattern
        var content = cell.defaultContentConfiguration()
        
        // Text configuration (Adaptive)
        content.text = item.title
        content.textProperties.font = .preferredFont(forTextStyle: .body)
        content.textProperties.color = .label
        
        // Icon configuration
        let iconName = item.iconName.isEmpty ? "doc.fill" : item.iconName
        content.image = UIImage(systemName: iconName)
        content.imageProperties.tintColor = tintColor(for: item.itemType)
        
        cell.contentConfiguration = content
        
        // Selection feedback
        let selectedBackground = UIView()
        selectedBackground.backgroundColor = .quaternarySystemFill
        cell.selectedBackgroundView = selectedBackground
        
        return cell
    }
    
    private func tintColor(for itemType: String) -> UIColor {
        switch itemType {
        case "PDF": return .systemRed
        case "Link": return .systemBlue
        case "Video": return .systemGreen
        default: return .secondaryLabel
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
