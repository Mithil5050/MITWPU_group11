import UIKit
import Supabase

// ✅ Create a simple struct to decode the data coming back from Supabase
struct UserProfile: Decodable {
    let username: String
    // We only need the username for now, but you can add institution/XP here later!
}

class ProfileViewController: UIViewController {

    // MARK: - UI Components
    var collectionView: UICollectionView!
    
    // MARK: - User Data (Default placeholders until data loads)
    var userName: String = "Loading..."
    var userEmail: String = "Loading..."
    var userImage: UIImage? = UIImage(named: "profile_placeholder")

    // MARK: - Settings Data
    struct SettingItem { let title: String; let icon: String; let color: UIColor; let isSwitch: Bool }
    let settingsData = [
        SettingItem(title: "Study Reminder", icon: "book", color: .systemBlue, isSwitch: true),
        SettingItem(title: "Notifications", icon: "bell", color: .systemRed, isSwitch: true),
        SettingItem(title: "Privacy & Security", icon: "lock", color: .systemGray, isSwitch: false),
        SettingItem(title: "Help & Support", icon: "questionmark.circle", color: .systemGray, isSwitch: false)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
        
        // Listen for updates to refresh Level Card
        NotificationCenter.default.addObserver(forName: .xpDidUpdate, object: nil, queue: .main) { [weak self] _ in
            self?.collectionView.reloadSections(IndexSet(integer: 1))
        }
        
        // ✅ Fetch the real user data as soon as the screen loads
        fetchUserData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Fetch Data from Supabase
    private func fetchUserData() {
        Task {
            do {
                // 1. Get the current logged-in user from Auth
                let user = try await supabase.auth.session.user
                let userId = user.id.uuidString
                let email = user.email ?? "No Email"
                
                // 2. Fetch their matching profile from your 'profiles' table
                let profile: UserProfile = try await supabase
                    .from("profiles")
                    .select("username") // Only grab the username to be efficient
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                // 3. Update the UI on the Main Thread
                DispatchQueue.main.async {
                    self.userName = profile.username
                    self.userEmail = email
                    
                    // Reload only the top section (Index 0) to show the new text
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
                
            } catch {
                print("Error fetching user data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.userName = "User Not Found"
                    self.userEmail = "Error loading email"
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
            }
        }
    }
    
    func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .black
        
        collectionView.register(UINib(nibName: "UserInfoCell", bundle: nil), forCellWithReuseIdentifier: "UserInfoCell")
        collectionView.register(UINib(nibName: "LevelCell", bundle: nil), forCellWithReuseIdentifier: "LevelCell")
        collectionView.register(UINib(nibName: "StatCardCell", bundle: nil), forCellWithReuseIdentifier: "StatCardCell")
        collectionView.register(UINib(nibName: "SettingsCell", bundle: nil), forCellWithReuseIdentifier: "SettingsCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "LogoutCell")
        
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    func openEditProfile() {
        let editVC = EditProfileViewController()
        editVC.delegate = self
        editVC.currentName = self.userName
        editVC.currentImage = self.userImage
        let nav = UINavigationController(rootViewController: editVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        present(nav, animated: true)
    }

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, env) -> NSCollectionLayoutSection? in
            
            // Section 0: User Info
            if sectionIndex == 0 {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(104)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 16, trailing: 16)
                return section
            }
            
            // Section 1: Level Card
            if sectionIndex == 1 {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                return section
            }
            
            // Section 2: Stats Grid
            if sectionIndex == 2 {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(82)))
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(82)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 16, trailing: 8)
                return section
            }
            
            // Section 3: Settings List
            if sectionIndex == 3 {
                var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                config.backgroundColor = .black
                return NSCollectionLayoutSection.list(using: config, layoutEnvironment: env)
            }
            
            // Section 4: Logout
            if sectionIndex == 4 {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 40, trailing: 16)
                return section
            }
            
            return nil
        }
    }
}

extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 5 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 2 ? 2 : (section == 3 ? settingsData.count : 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserInfoCell", for: indexPath) as! UserInfoCell
            cell.configure(name: self.userName, email: self.userEmail)
            if let img = self.userImage { cell.pfp.image = img }
            cell.didTapEdit = { [weak self] in self?.openEditProfile() }
            return cell
        }
        
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelCell", for: indexPath) as! LevelCell
            // XP RESET LOGIC
            let displayXP = ProgressDataManager.shared.totalXP % 100
            cell.configure(level: ProgressDataManager.shared.userLevel, currentXP: displayXP, maxXP: 100)
            return cell
        }
        
        if indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StatCardCell", for: indexPath) as! StatCardCell
            if indexPath.item == 0 { cell.configure(title: "Streak", value: "7 Days", icon: "flame", color: .systemOrange) }
            else { cell.configure(title: "Badges", value: "8 Unlocked", icon: "trophy", color: .systemYellow) }
            return cell
        }
        
        if indexPath.section == 3 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            let data = settingsData[indexPath.item]
            cell.configure(title: data.title, icon: data.icon, color: data.color, isSwitch: data.isSwitch)
            return cell
        }
        
        // Logout Cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LogoutCell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let lbl = UILabel(frame: cell.bounds); lbl.text = "Log Out"; lbl.textColor = .systemRed; lbl.textAlignment = .center
        cell.contentView.addSubview(lbl)
        return cell
    }
}

extension ProfileViewController: EditProfileDelegate {
    func didUpdateProfile(name: String, image: UIImage?) {
        self.userName = name; if let img = image { self.userImage = img }
        collectionView.reloadSections(IndexSet(integer: 0))
    }
}
