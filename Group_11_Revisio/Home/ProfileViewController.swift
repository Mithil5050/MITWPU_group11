import UIKit

// Define sections for the grouped table view
enum ProfileSection: Int, CaseIterable {
    case userInfo = 0
    case settings
    case actions // For Logout
}

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Updated Data Model: Includes Icon Name and Color
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
        
        // Back Button
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        backButton.tintColor = .systemGray2
        self.navigationItem.leftBarButtonItem = backButton
        
        setupTableView()
    }
    
    @objc func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        // Register your custom UserInfoCell XIB
        // Make sure the file name is "UserInfoCell"
        let userInfoNib = UINib(nibName: "UserInfoCell", bundle: nil)
        tableView.register(userInfoNib, forCellReuseIdentifier: "UserInfoCellID")
        
        // Register standard cell for settings
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return ProfileSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch ProfileSection.allCases[section] {
        case .userInfo: return 1
        case .settings: return settingsOptions.count
        case .actions: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch ProfileSection.allCases[section] {
        case .settings: return "Settings"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = ProfileSection.allCases[indexPath.section]
        
        switch section {
        case .userInfo:
            // FIX: Use 'UserInfoCellTableViewCell' instead of 'UserInfoCell'
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserInfoCellID", for: indexPath) as? UserInfoCellTableViewCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            return cell
            
        case .settings:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            let setting = settingsOptions[indexPath.row]
            
            // Configure Text
            cell.textLabel?.text = setting.title
            
            // Configure Icon
            if let iconName = setting.icon, let iconColor = setting.color {
                cell.imageView?.image = UIImage(systemName: iconName)
                cell.imageView?.tintColor = iconColor
            } else {
                cell.imageView?.image = nil
            }
            
            // Configure Accessory
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
            
            // Dark mode adaptation
            cell.backgroundColor = UIColor.systemGroupedBackground
            
            return cell
            
        case .actions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            
            cell.textLabel?.text = "Logout"
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.textAlignment = .center
            
            cell.imageView?.image = nil
            cell.accessoryView = nil
            cell.accessoryType = .none
            cell.backgroundColor = UIColor.systemGroupedBackground
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 {
            print("Logout Tapped")
        }
    }
    
    // MARK: - Heights
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = ProfileSection.allCases[indexPath.section]
        switch section {
        case .userInfo: return 140
        case .settings, .actions: return 52
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 { return 40.0 }
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20.0
    }
}
