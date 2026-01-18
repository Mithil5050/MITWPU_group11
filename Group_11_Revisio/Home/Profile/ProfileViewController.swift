import UIKit

// Define sections for the grouped table view
enum ProfileSection: Int, CaseIterable {
    case userInfo = 0
    case settings
    case actions // For Logout
}

class ProfileViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    // 1. Data for the User Info
    var userName: String = "Mithil"
    var userProfileImage: UIImage? = UIImage(named: "profile_placeholder") // Or your asset name
    
    // 2. "Old Data" - The Settings Options
    let settingsOptions: [(title: String, icon: String?, color: UIColor?, type: String)] = [
        ("Study Reminder", "book", .systemBlue, "Switch"),
        ("Show Achievements", "trophy", .systemYellow, "Switch"),
        ("Notifications", "bell.badge", .systemRed, "Switch"),
        ("Privacy & Security", nil, nil, "Disclosure"),
        ("Help & Support", nil, nil, "Disclosure")
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = ""
        setupNavigationBar()
        setupTableView()
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        backButton.tintColor = .systemGray2
        self.navigationItem.leftBarButtonItem = backButton
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        // Register Custom XIB for Top Cell
        // Ensure "UserInfoCell" matches your XIB filename exactly
        let userInfoNib = UINib(nibName: "UserInfoCell", bundle: nil)
        tableView.register(userInfoNib, forCellReuseIdentifier: "UserInfoCellID")
        
        // Register Standard Cell for Settings
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
    }
    
    // MARK: - Actions
    @objc func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Function to open the Edit Modal
    func openEditProfileModal() {
        let editVC = EditProfileViewController() // Ensure this class exists from previous steps
        editVC.delegate = self // Set delegate to receive updates
        editVC.currentName = self.userName
        editVC.currentImage = self.userProfileImage
        
        let nav = UINavigationController(rootViewController: editVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate
extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return ProfileSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch ProfileSection.allCases[section] {
        case .userInfo: return 1
        case .settings: return settingsOptions.count // ✅ Restores your settings rows
        case .actions: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == ProfileSection.settings.rawValue {
            return "Settings"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = ProfileSection.allCases[indexPath.section]
        
        switch section {
        case .userInfo:
            // Top Card with Edit Button
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserInfoCellID", for: indexPath) as? UserInfoCellTableViewCell else {
                return UITableViewCell()
            }
            
            // 1. Configure with current data
            cell.configure(name: userName, image: userProfileImage)
            
            // 2. Handle the "Edit" button tap from the cell
            cell.didTapEditButton = { [weak self] in
                self?.openEditProfileModal()
            }
            
            cell.selectionStyle = .none
            return cell
            
        case .settings:
            // Your Settings List
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            let setting = settingsOptions[indexPath.row]
            
            cell.textLabel?.text = setting.title
            
            if let iconName = setting.icon, let iconColor = setting.color {
                cell.imageView?.image = UIImage(systemName: iconName)
                cell.imageView?.tintColor = iconColor
            } else {
                cell.imageView?.image = nil
            }
            
            // Accessories (Switch or Arrow)
            if setting.type == "Switch" {
                let settingSwitch = UISwitch()
                settingSwitch.isOn = true
                settingSwitch.onTintColor = .systemGreen
                cell.accessoryView = settingSwitch
                cell.selectionStyle = .none
                cell.accessoryType = .none
            } else {
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
            }
            
            cell.backgroundColor = UIColor.systemGroupedBackground
            return cell
            
        case .actions:
            // Logout Button
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            cell.textLabel?.text = "Log Out"
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.textAlignment = .center
            cell.imageView?.image = nil
            cell.accessoryView = nil
            cell.backgroundColor = UIColor.systemGroupedBackground
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Handle Logout Tap
        if indexPath.section == ProfileSection.actions.rawValue {
            let alert = UIAlertController(title: "Log Out", message: "Are you sure?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Log Out", style: .destructive))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 { return 140 } // Height for Top Card
        return 52 // Height for standard rows
    }
}

// MARK: - EditProfileDelegate
// Receives data back from the Edit Screen
extension ProfileViewController: EditProfileDelegate {
    func didUpdateProfile(name: String, image: UIImage?) {
        // 1. Update Data Source
        self.userName = name
        self.userProfileImage = image
        
        // 2. Refresh the Top Section Only
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}
