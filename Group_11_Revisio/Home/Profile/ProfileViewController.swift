//
//  ProfileViewController.swift
//  Group_11_Revisio
//

import UIKit
import Supabase

// ✅ Structure to decode Supabase data
struct UserProfile: Decodable {
    let username: String
    let avatar_url: String?
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
        
        // Listen for updates to refresh Profile info
        NotificationCenter.default.addObserver(self, selector: #selector(reloadProfile), name: NSNotification.Name("ProfileDidUpdate"), object: nil)
        
        // Listen for updates to refresh Level Card
        NotificationCenter.default.addObserver(forName: .xpDidUpdate, object: nil, queue: .main) { [weak self] _ in
            self?.collectionView.reloadSections(IndexSet(integersIn: 1...2))
        }
        
        // ✅ Add Close Button to Navigation Bar
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let xImage = UIImage(systemName: "multiply", withConfiguration: config)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: xImage, style: .plain, target: self, action: #selector(handleDismiss))
        
        fetchUserData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Navigation Logic
    @objc private func handleDismiss() {
        if isBeingPresented || navigationController?.presentingViewController != nil {
            self.dismiss(animated: true)
        } else {
            self.tabBarController?.selectedIndex = 0
        }
    }
    
    @objc private func reloadProfile() {
        fetchUserData()
    }
    
    // MARK: - Fetch Data Logic
    private func fetchUserData() {
        Task {
            do {
                let user = try await supabase.auth.session.user
                let userId = user.id.uuidString
                let email = user.email ?? "No Email"
                
                let profile: UserProfile = try await supabase
                    .from("profiles")
                    .select("username, avatar_url")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                DispatchQueue.main.async {
                    self.userName = profile.username
                    self.userEmail = email
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
                
                if let avatarString = profile.avatar_url {
                    // Bypass the cache to get the newest photo
                    let cacheBuster = "?v=\(Date().timeIntervalSince1970)"
                    if let url = URL(string: avatarString + cacheBuster) {
                        downloadProfileImage(from: url)
                    }
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
    
    private func downloadProfileImage(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let downloadedImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.userImage = downloadedImage
                        self.collectionView.reloadSections(IndexSet(integer: 0))
                    }
                }
            } catch {
                print("Failed to download profile picture: \(error.localizedDescription)")
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

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, env) -> NSCollectionLayoutSection? in
            if sectionIndex == 0 {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(104)))
                let section = NSCollectionLayoutSection(group: NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item]))
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 16, trailing: 16)
                return section
            } else if sectionIndex == 1 {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80)))
                let section = NSCollectionLayoutSection(group: NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item]))
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                return section
            } else if sectionIndex == 2 {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(82)))
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(82)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 16, trailing: 8)
                return section
            } else if sectionIndex == 3 {
                var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                config.backgroundColor = .black
                return NSCollectionLayoutSection.list(using: config, layoutEnvironment: env)
            } else {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60)))
                let section = NSCollectionLayoutSection(group: NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item]))
                section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 40, trailing: 16)
                return section
            }
        }
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

    private func handleLogout() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
            Task {
                do {
                    try await supabase.auth.signOut()
                    DispatchQueue.main.async { self.transitionToLoginScreen() }
                } catch {
                    DispatchQueue.main.async {
                        let errorAlert = UIAlertController(title: "Logout Failed", message: error.localizedDescription, preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        }))
        present(alert, animated: true)
    }

    private func transitionToLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")
        let nav = UINavigationController(rootViewController: onboardingVC)
        nav.isNavigationBarHidden = true
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = nav
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
}

// MARK: - Extensions
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
        }  else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelCell", for: indexPath) as! LevelCell
            
            let manager = ProgressDataManager.shared
            
            
            cell.configure(
                level: manager.userLevel,
                currentXP: manager.currentLevelXP,
                maxXP: manager.pointsPerLevel
            )
            return cell
        } else if indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StatCardCell", for: indexPath) as! StatCardCell
            if indexPath.item == 0 {
                let streak = ProgressDataManager.shared.currentStreak
                let streakSuffix = streak == 1 ? "Day" : "Days"
                cell.configure(title: "Streak", value: "\(streak) \(streakSuffix)", icon: "flame.fill", color: .systemOrange)
            } else {
                cell.configure(title: "Badges", value: "8 Unlocked", icon: "trophy.fill", color: .systemYellow)
            }
            return cell
        } else if indexPath.section == 3 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            let data = settingsData[indexPath.item]
            cell.configure(title: data.title, icon: data.icon, color: data.color, isSwitch: data.isSwitch)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LogoutCell", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            let lbl = UILabel(frame: cell.bounds)
            lbl.text = "Log Out"
            lbl.textColor = .systemRed
            lbl.textAlignment = .center
            cell.contentView.addSubview(lbl)
            return cell
        }
    }

    // ✅ Cleaned up duplicate functions!
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
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
