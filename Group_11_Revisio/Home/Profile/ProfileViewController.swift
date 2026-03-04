import UIKit
import Supabase

// ✅ Structure to decode Supabase data
struct UserProfile: Decodable {
    let username: String
}

class ProfileViewController: UIViewController {

    // MARK: - UI Components
    var collectionView: UICollectionView!
    
    // MARK: - User Data (Placeholders)
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()
        
        // Listen for XP and Streak updates to refresh cards
        NotificationCenter.default.addObserver(forName: .xpDidUpdate, object: nil, queue: .main) { [weak self] _ in
            self?.collectionView.reloadSections(IndexSet(integersIn: 1...2))
        }
        
        fetchUserData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    private func handleLogout() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            Task {
                do {
                    // 1. Sign out from Supabase session
                    try await SupabaseManager.shared.client.auth.signOut()
                    
                    // 2. Return to Onboarding flow
                    DispatchQueue.main.async {
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let delegate = windowScene.delegate as? SceneDelegate else { return }
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")
                        let nav = UINavigationController(rootViewController: onboardingVC)
                        nav.isNavigationBarHidden = true
                        
                        delegate.window?.rootViewController = nav
                        UIView.transition(with: delegate.window!, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                    }
                } catch {
                    print("Error logging out: \(error)")
                }
            }
        })
        
        present(alert, animated: true)
    }

    // MARK: - Supabase Data Fetching
    private func fetchUserData() {
        Task {
            do {
                let user = try await SupabaseManager.shared.client.auth.session.user
                let userId = user.id
                let email = user.email ?? "No Email"
                
                let profile: UserProfile = try await SupabaseManager.shared.client
                    .from("profiles")
                    .select("username")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                DispatchQueue.main.async {
                    self.userName = profile.username
                    self.userEmail = email
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
                
            } catch {
                print("❌ Error fetching user data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.userName = "User Not Found"
                    self.userEmail = "Offline"
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
            }
        }
    }
    
    // MARK: - CollectionView Setup
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
            switch sectionIndex {
            case 0:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(104)))
                let section = NSCollectionLayoutSection(group: NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item]))
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 16, trailing: 16)
                return section
            case 1:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80)))
                let section = NSCollectionLayoutSection(group: NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item]))
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                return section
            case 2:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(82)))
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(82)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 16, trailing: 8)
                return section
            case 3:
                var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                config.backgroundColor = .black
                return NSCollectionLayoutSection.list(using: config, layoutEnvironment: env)
            case 4:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60)))
                let section = NSCollectionLayoutSection(group: NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item]))
                section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 40, trailing: 16)
                return section
            default: return nil
            }
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
            let displayXP = ProgressDataManager.shared.currentLevelXP
            cell.configure(level: ProgressDataManager.shared.userLevel, currentXP: displayXP, maxXP: 100)
            return cell
        }
        
        if indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StatCardCell", for: indexPath) as! StatCardCell
            if indexPath.item == 0 {
                let streak = ProgressDataManager.shared.currentStreak
                cell.configure(title: "Streak", value: "\(streak) Days", icon: "flame.fill", color: .systemOrange)
            } else {
                cell.configure(title: "Badges", value: "8 Unlocked", icon: "trophy.fill", color: .systemYellow)
            }
            return cell
        }
        
        if indexPath.section == 3 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            let data = settingsData[indexPath.item]
            cell.configure(title: data.title, icon: data.icon, color: data.color, isSwitch: data.isSwitch)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LogoutCell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let lbl = UILabel(frame: cell.bounds); lbl.text = "Log Out"; lbl.textColor = .systemRed; lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 16, weight: .medium)
        cell.contentView.addSubview(lbl)
        return cell
    }

    // ✅ Handle tapping the Logout row or any other selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 4 {
            handleLogout()
        }
    }
}

extension ProfileViewController: EditProfileDelegate {
    func didUpdateProfile(name: String, image: UIImage?) {
        self.userName = name
        if let img = image { self.userImage = img }
        collectionView.reloadSections(IndexSet(integer: 0))
    }
}
