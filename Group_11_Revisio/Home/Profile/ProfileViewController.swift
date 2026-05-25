import UIKit
import Supabase

struct UserProfile: Decodable {
    let username: String
    let avatar_url: String?
}

class ProfileViewController: UIViewController {

    var collectionView: UICollectionView!

    var userName: String = "Loading..."
    var userEmail: String = "Loading..."
    var userImage: UIImage? = UIImage(named: "profile_placeholder")

    struct SettingItem { let title: String; let icon: String; let color: UIColor; let isSwitch: Bool }
    let settingsData = [
        SettingItem(title: "Study Reminder", icon: "book", color: .systemBlue, isSwitch: true),
        SettingItem(title: "Notifications", icon: "bell", color: .systemRed, isSwitch: true),
        SettingItem(title: "Privacy & Security", icon: "lock", color: .systemGray, isSwitch: false),
        SettingItem(title: "Help & Support", icon: "questionmark.circle", color: .systemGray, isSwitch: false)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupCollectionView()

        NotificationCenter.default.addObserver(self, selector: #selector(reloadProfile), name: NSNotification.Name("ProfileDidUpdate"), object: nil)

        NotificationCenter.default.addObserver(forName: .xpDidUpdate, object: nil, queue: .main) { [weak self] _ in
            self?.collectionView.reloadSections(IndexSet(integersIn: 1...2))
        }

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let xImage = UIImage(systemName: "multiply", withConfiguration: config)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: xImage, style: .plain, target: self, action: #selector(handleDismiss))

        fetchUserData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadSections(IndexSet(integersIn: 1...2))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

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

    private func fetchUserData() {
            Task {
                do {
                    let user = try await supabase.auth.session.user
                    let userId = user.id.uuidString
                    let email = user.email ?? "No Email"

                    // Set email immediately
                    DispatchQueue.main.async { self.userEmail = email }

                    // FIX: Ensure ProgressDataManager restores data for THIS specific user ID
                    ProgressDataManager.shared.restoreFromSupabase()

                    do {
                        let profile: UserProfile = try await supabase
                            .from("profiles")
                            .select("username, avatar_url")
                            .eq("id", value: userId) // Correctly uses unique ID
                            .single()
                            .execute()
                            .value

                        DispatchQueue.main.async {
                            self.userName = profile.username
                            self.collectionView.reloadSections(IndexSet(integer: 0))
                        }

                        if let avatarString = profile.avatar_url {
                            let cacheBuster = "?v=\(Date().timeIntervalSince1970)"
                            if let url = URL(string: avatarString + cacheBuster) {
                                downloadProfileImage(from: url)
                            }
                        }
                    } catch {
                        let googleName = user.userMetadata["full_name"]?.value as? String ?? "New Student"
                        DispatchQueue.main.async {
                            self.userName = googleName
                            self.collectionView.reloadSections(IndexSet(integer: 0))
                        }
                    }
                } catch {
                    print("❌ Error: \(error.localizedDescription)")
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
                print("Failed to download image: \(error.localizedDescription)")
            }
        }
    }

    func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground

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
                config.backgroundColor = .systemGroupedBackground
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
        let alert = UIAlertController(title: "Log Out", message: "Are you sure?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
            // 1. Reset the local phone storage first
            self.resetLocalData()

            Task {
                do {
                    try await supabase.auth.signOut()
                    DispatchQueue.main.async { self.transitionToLoginScreen() }
                } catch {
                    print("Logout Failed: \(error)")
                }
            }
        }))
        present(alert, animated: true)
    }

    private func resetLocalData() {
        // These keys match the ones used in your ProgressDataManager
        let keys = [
            "user_total_xp",
            "user_current_level",
            "user_current_streak",
            "earned_badge_ids",
            "unlocked_badge_ids",
            "stat_quizzes_done",
            "stat_high_quizzes",
            "stat_daily_solved",
            "stat_cards_viewed"
        ]

        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }

        // Reset the singleton so it doesn't hold old data in memory
        ProgressDataManager.shared.totalXP = 0
        ProgressDataManager.shared.userLevel = 1
    }

    private func transitionToLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        let nav = UINavigationController(rootViewController: loginVC)
        nav.isNavigationBarHidden = true
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = nav
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: nil, completion: nil)
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
            applyCardStyle(to: cell)
            return cell

        } else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelCell", for: indexPath) as! LevelCell
            let manager = ProgressDataManager.shared
            cell.configure(
                level: manager.userLevel,
                currentXP: manager.currentLevelXP,
                maxXP: manager.pointsPerLevel
            )
            applyCardStyle(to: cell)
            return cell

        } else if indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StatCardCell", for: indexPath) as! StatCardCell
            if indexPath.item == 0 {
                let streak = ProgressDataManager.shared.currentStreak
                let streakSuffix = streak == 1 ? "Day" : "Days"
                cell.configure(title: "Streaks", value: "\(streak) \(streakSuffix)", icon: "flame.fill", color: .systemOrange)
            } else {
                let earnedCount = Badging.allMilestones.filter { $0.isEarned }.count
                cell.configure(title: "Badges", value: "\(earnedCount) Earned", icon: "trophy.fill", color: .systemYellow)
            }
            applyCardStyle(to: cell)
            return cell

        } else if indexPath.section == 3 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            let data = settingsData[indexPath.item]
            cell.configure(title: data.title, icon: data.icon, color: data.color, isSwitch: data.isSwitch)
            return cell

        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LogoutCell", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.layer.cornerRadius = 12
            cell.clipsToBounds = true
            let lbl = UILabel(frame: cell.contentView.bounds)
            lbl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            lbl.text = "Log Out"
            lbl.textColor = .systemRed
            lbl.textAlignment = .center
            lbl.font = .systemFont(ofSize: 17, weight: .medium)
            cell.contentView.addSubview(lbl)
            return cell
        }
    }

    private func applyCardStyle(to cell: UICollectionViewCell) {
        cell.layer.cornerRadius = 16
        cell.clipsToBounds = false
        cell.layer.shadowColor = UIColor.black.cgColor
        let isDark = traitCollection.userInterfaceStyle == .dark
        cell.layer.shadowOpacity = isDark ? 0.30 : 0.06
        cell.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.layer.shadowRadius = isDark ? 7 : 3
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        if indexPath.section == 1 {
            let xpVC = XPInfoSheetViewController()
            navigationController?.pushViewController(xpVC, animated: true)

        } else if indexPath.section == 2 {
            if indexPath.item == 0 {
                let streaksVC = StreaksCalendarViewController()
                navigationController?.pushViewController(streaksVC, animated: true)
            } else if indexPath.item == 1 {
                let badgesVC = EarnedBadgesViewController()
                navigationController?.pushViewController(badgesVC, animated: true)
            }

        } else if indexPath.section == 4 {
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
