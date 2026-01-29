import UIKit

class ProfileViewController: UIViewController {

    // MARK: - UI Components
    var collectionView: UICollectionView!
    
    // MARK: - User Data (State)
    // We store these here so we can update them when you edit
    var userName: String = "Alex Smith"
    var userEmail: String = "alexsmith@gmail.com"
    var userImage: UIImage? = UIImage(named: "profile_placeholder") // Or systemName "person.crop.circle.fill"

    // MARK: - Settings Data
    struct SettingItem { let title: String; let icon: String; let color: UIColor; let isSwitch: Bool }
    let settingsData = [
        SettingItem(title: "Study Reminder", icon: "book", color: .systemBlue, isSwitch: true),
        SettingItem(title: "Notifications", icon: "bell", color: .systemRed, isSwitch: true),
        SettingItem(title: "Privacy & Security", icon: "lock", color: .systemGray, isSwitch: false),
        SettingItem(title: "Help & Support", icon: "questionmark.circle", color: .systemGray, isSwitch: false)
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
    }
    
    // MARK: - Setup
    func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .black
        
        // Register XIBs
        collectionView.register(UINib(nibName: "UserInfoCell", bundle: nil), forCellWithReuseIdentifier: "UserInfoCell")
        collectionView.register(UINib(nibName: "LevelCell", bundle: nil), forCellWithReuseIdentifier: "LevelCell")
        collectionView.register(UINib(nibName: "StatCardCell", bundle: nil), forCellWithReuseIdentifier: "StatCardCell")
        collectionView.register(UINib(nibName: "SettingsCell", bundle: nil), forCellWithReuseIdentifier: "SettingsCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "LogoutCell")
        
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    // MARK: - Navigation Actions
    func openEditProfile() {
        let editVC = EditProfileViewController()
        editVC.delegate = self // Connect the delegate!
        editVC.currentName = self.userName
        editVC.currentImage = self.userImage
        
        // Present nicely
        let nav = UINavigationController(rootViewController: editVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()] // iOS 15+ sheet
        }
        present(nav, animated: true)
    }

    // MARK: - Compositional Layout
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, env) -> NSCollectionLayoutSection? in
            
            // 1. User Info Section (Full Width)
            if sectionIndex == 0 {
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(104)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 16, trailing: 16)
                return section
            }
            
            // 2. Level Section (Full Width)
            if sectionIndex == 1 {
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                return section
            }
            
            // 3. Stats Grid (2 Columns)
            if sectionIndex == 2 {
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(82)))
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(82)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 16, trailing: 8)
                return section
            }
            
            // 4. Settings List
            if sectionIndex == 3 {
                var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                config.backgroundColor = .black
                config.showsSeparators = true
                return NSCollectionLayoutSection.list(using: config, layoutEnvironment: env)
            }
            
            // 5. Logout
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60)))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item])
            return NSCollectionLayoutSection(group: group)
        }
    }
}

// MARK: - DataSource & Delegate
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 5 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 2 { return 2 } // Streak & Badges
        if section == 3 { return settingsData.count }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // 0. User Info (CONNECTED!)
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserInfoCell", for: indexPath) as! UserInfoCell
            
            // 1. Configure Text
            cell.configure(name: self.userName, email: self.userEmail)
            
            // 2. Configure Image (Manually since configure() didn't include it in your file)
            if let img = self.userImage {
                cell.pfp.image = img
            }
            
            // 3. Connect the Closure Action
            cell.didTapEdit = { [weak self] in
                self?.openEditProfile()
            }
            
            return cell
        }
        
        // 1. Level
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelCell", for: indexPath) as! LevelCell
            cell.configure(level: 2, currentXP: 15, maxXP: 70)
            return cell
        }
        
        // 2. Stats Grid
        if indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StatCardCell", for: indexPath) as! StatCardCell
            if indexPath.item == 0 {
                cell.configure(title: "Streak", value: "7 Days", icon: "flame", color: .systemOrange)
            } else {
                cell.configure(title: "Badges", value: "8 Unlocked", icon: "trophy", color: .systemYellow)
            }
            return cell
        }
        
        // 3. Settings
        if indexPath.section == 3 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            let data = settingsData[indexPath.item]
            cell.configure(title: data.title, icon: data.icon, color: data.color, isSwitch: data.isSwitch)
            return cell
        }
        
        // 4. Logout
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LogoutCell", for: indexPath)
        for view in cell.contentView.subviews { view.removeFromSuperview() }
        let lbl = UILabel(frame: cell.bounds)
        lbl.text = "Log Out"
        lbl.textColor = .systemRed
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 16, weight: .medium)
        cell.contentView.addSubview(lbl)
        return cell
    }
    
    // Handle Logout Selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 4 {
            let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Log Out", style: .destructive))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        }
    }
}

// MARK: - EditProfileDelegate Implementation
// This updates the screen when you hit "Save" in the edit screen
extension ProfileViewController: EditProfileDelegate {
    func didUpdateProfile(name: String, image: UIImage?) {
        // 1. Update State
        self.userName = name
        if let newImage = image {
            self.userImage = newImage
        }
        
        // 2. Reload ONLY the Profile Card section to reflect changes
        collectionView.reloadSections(IndexSet(integer: 0))
    }
}
