import UIKit

// Define sections for the grouped table view
enum ProfileSection: Int, CaseIterable {
    case userInfo = 0
    case settings
    case actions // For Logout
}

// NOTE: Assume this custom class exists in your project with the required outlets (nameLabel, emailLabel, editProfileButton, profileImageView)
// You MUST create this UserInfoCell.swift and UserInfoCell.xib
class UserInfoCell: UITableViewCell { }

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Settings data structure (title, initial state/type)
    let settingsOptions: [(title: String, type: String)] = [
        ("Study Reminder", "Switch"),
        ("Mindful Breaks", "Switch"),
        ("Show Achievements", "Switch"),
        ("Notifications", "Switch"),
        ("Privacy & Security", "Disclosure"),
        ("Help & Support", "Disclosure")
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Profile"
        setupTableView()
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        // ⬇️ FIX 1: Register the custom UserInfoCell XIB (Assuming name "UserInfoCell") ⬇️
        let userInfoNib = UINib(nibName: "UserInfoCell", bundle: nil)
        tableView.register(userInfoNib, forCellReuseIdentifier: "UserInfoCellID")
        
        // Register standard cell types for settings/actions
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
            // ⬇️ FIX 2: Dequeue the custom UserInfoCell ⬇️
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserInfoCellID", for: indexPath) as? UserInfoCell else {
                // Fallback (should be replaced with proper UserInfoCell registration/creation)
                let placeholderCell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                placeholderCell.selectionStyle = .none
                placeholderCell.textLabel?.text = "Alex Smith"
                placeholderCell.detailTextLabel?.text = "alexsmith@gmail.com"
                return placeholderCell
            }
            
            cell.selectionStyle = .none
            
            // ⬇️ NOTE: In your real UserInfoCell, you would call a configure method here: ⬇️
            /* cell.configure(
                name: "Alex Smith",
                email: "alexsmith@gmail.com",
                image: UIImage(systemName: "person.circle.fill") ?? UIImage()
            )
            // You would also handle the Edit Profile Button action assignment here (e.g., cell.onEditTapped = { self.performSegue(...) })
            */
            
            return cell
            
        case .settings:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            let setting = settingsOptions[indexPath.row]
            
            cell.textLabel?.text = setting.title
            
            if setting.type == "Switch" {
                let settingSwitch = UISwitch()
                settingSwitch.isOn = true
                cell.accessoryView = settingSwitch
                cell.selectionStyle = .none
                cell.accessoryType = .none
            } else {
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
            }
            return cell
            
        case .actions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            
            cell.textLabel?.text = "Logout"
            cell.textLabel?.textColor = .systemBlue
            cell.textLabel?.textAlignment = .center
            cell.accessoryView = nil
            cell.accessoryType = .none
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = ProfileSection.allCases[indexPath.section]
        
        if section == .actions {
            print("Logout Tapped: Initiate log out process.")
        } else if section == .settings {
            let settingTitle = settingsOptions[indexPath.row].title
            if settingsOptions[indexPath.row].type == "Disclosure" {
                print("Navigate to \(settingTitle) screen.")
                // TODO: Perform Segue to the relevant detailed settings view
            }
        }
    }
    
    // Set heights for visual spacing
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = ProfileSection.allCases[indexPath.section]
        switch section {
        case .userInfo: return 140 // Taller cell for the profile card
        case .settings, .actions: return 52 // Adds ~8 points of vertical space between settings rows
        default: return 44
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionType = ProfileSection.allCases[section]
        switch sectionType {
        case .settings: return 40.0 // Space above the "Settings" title
        default: return 0.0
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sectionType = ProfileSection.allCases[section]
        switch sectionType {
        case .userInfo: return 20.0 // Gap between User Info card and Settings header
        case .settings: return 20.0 // Gap between Settings block and Logout button
        default: return 1.0 // Minimal space after Logout
        }
    }
}
