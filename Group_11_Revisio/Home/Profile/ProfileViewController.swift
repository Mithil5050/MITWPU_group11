//
//  ProfileViewController.swift
//  Group_11_Revisio
//

import UIKit
import Supabase

struct UserProfile: Decodable {
    let username: String
    let avatar_url: String?
}

class ProfileViewController: UIViewController {

    // MARK: - UI
    var collectionView: UICollectionView!

    // MARK: - User Data
    var userName: String   = "Loading..."
    var userEmail: String  = "Loading..."
    var userImage: UIImage? = UIImage(named: "profile_placeholder")

    // MARK: - Settings Data
    struct SettingItem { let title: String; let icon: String; let color: UIColor; let isSwitch: Bool }
    let settingsData = [
        SettingItem(title: "Study Reminder",     icon: "book",                color: .systemBlue, isSwitch: true),
        SettingItem(title: "Notifications",      icon: "bell",                color: .systemRed,  isSwitch: true),
        SettingItem(title: "Privacy & Security", icon: "lock",                color: .systemGray, isSwitch: false),
        SettingItem(title: "Help & Support",     icon: "questionmark.circle", color: .systemGray, isSwitch: false)
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCollectionView()

        NotificationCenter.default.addObserver(self, selector: #selector(reloadProfile),
                                               name: NSNotification.Name("ProfileDidUpdate"), object: nil)
        NotificationCenter.default.addObserver(forName: .xpDidUpdate, object: nil, queue: .main) { [weak self] _ in
            self?.collectionView.reloadSections(IndexSet(integersIn: 1...2))
        }

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "multiply", withConfiguration: config),
            style: .plain, target: self, action: #selector(handleDismiss)
        )

        fetchUserData()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Navigation handlers

    @objc private func handleDismiss() {
        if isBeingPresented || navigationController?.presentingViewController != nil {
            dismiss(animated: true)
        } else {
            tabBarController?.selectedIndex = 0
        }
    }

    @objc private func reloadProfile() { fetchUserData() }

    // XP card — pushes XP Info screen (how XP works explanation)
    private func openXPInfo() {
        let vc = XPInfoSheetViewController(nibName: "XPInfoSheetViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }

    // Pushes Streak Details — same screen as Progress tab
    private func openStreakDetails() {
        let vc = StreaksCalendarViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // Pushes Earned Badges summary screen
    private func openBadges() {
        let vc = EarnedBadgesViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Fetch Data

    private func fetchUserData() {
        Task {
            do {
                let user = try await supabase.auth.session.user
                let profile: UserProfile = try await supabase
                    .from("profiles").select("username, avatar_url")
                    .eq("id", value: user.id.uuidString).single().execute().value
                DispatchQueue.main.async {
                    self.userName  = profile.username
                    self.userEmail = user.email ?? "No Email"
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
                if let avatarString = profile.avatar_url,
                   let url = URL(string: avatarString + "?v=\(Date().timeIntervalSince1970)") {
                    downloadProfileImage(from: url)
                }
            } catch {
                DispatchQueue.main.async {
                    self.userName  = "User Not Found"
                    self.userEmail = "Offline"
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
            }
        }
    }

    private func downloadProfileImage(from url: URL) {
        Task {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.userImage = img
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
            }
        }
    }

    // MARK: - CollectionView Setup

    func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor  = .black
        collectionView.register(UINib(nibName: "UserInfoCell",  bundle: nil), forCellWithReuseIdentifier: "UserInfoCell")
        collectionView.register(UINib(nibName: "LevelCell",     bundle: nil), forCellWithReuseIdentifier: "LevelCell")
        collectionView.register(UINib(nibName: "StatCardCell",  bundle: nil), forCellWithReuseIdentifier: "StatCardCell")
        collectionView.register(UINib(nibName: "SettingsCell",  bundle: nil), forCellWithReuseIdentifier: "SettingsCell")
        collectionView.register(UICollectionViewCell.self,                    forCellWithReuseIdentifier: "LogoutCell")
        collectionView.dataSource = self
        collectionView.delegate   = self
        view.addSubview(collectionView)
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
            default:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60)))
                let section = NSCollectionLayoutSection(group: NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item]))
                section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 40, trailing: 16)
                return section
            }
        }
    }

    func openEditProfile() {
        let editVC = EditProfileViewController()
        editVC.delegate     = self
        editVC.currentName  = userName
        editVC.currentImage = userImage
        let nav = UINavigationController(rootViewController: editVC)
        if let sheet = nav.sheetPresentationController { sheet.detents = [.medium(), .large()] }
        present(nav, animated: true)
    }

    private func handleLogout() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            Task {
                do {
                    try await supabase.auth.signOut()
                    DispatchQueue.main.async { self.transitionToLoginScreen() }
                } catch {
                    DispatchQueue.main.async {
                        let err = UIAlertController(title: "Logout Failed", message: error.localizedDescription, preferredStyle: .alert)
                        err.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(err, animated: true)
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    private func transitionToLoginScreen() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC = sb.instantiateViewController(withIdentifier: "OnboardingViewController")
        let nav = UINavigationController(rootViewController: onboardingVC)
        nav.isNavigationBarHidden = true
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = nav
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: nil)
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 5 }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 2: return 2
        case 3: return settingsData.count
        default: return 1
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {

        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserInfoCell",
                                                          for: indexPath) as! UserInfoCell
            cell.configure(name: userName, email: userEmail)
            if let img = userImage { cell.pfp.image = img }
            cell.didTapEdit = { [weak self] in self?.openEditProfile() }
            return cell

        case 1:
            // XP / Level card — whole card is tappable, no ⓘ button
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelCell",
                                                          for: indexPath) as! LevelCell
            let m = ProgressDataManager.shared
            cell.configure(level: m.userLevel,
                           currentXP: m.currentLevelXP,
                           maxXP: m.requiredXPForCurrentLevel)
            cell.delegate = self
            return cell

        case 2:
            // Streak (item 0) and Badges (item 1)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StatCardCell",
                                                          for: indexPath) as! StatCardCell
            if indexPath.item == 0 {
                let streak = ProgressDataManager.shared.currentStreak
                cell.configure(title: "Streak", value: "\(streak) Days",
                               icon: "flame.fill", color: .systemOrange)
            } else {
                let earned = ProgressDataManager.shared.earnedBadgeCount
                cell.configure(title: "Badges", value: "\(earned) Earned",
                               icon: "trophy.fill", color: .systemIndigo)
            }
            return cell

        case 3:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SettingsCell",
                                                          for: indexPath) as! SettingsCell
            let data = settingsData[indexPath.item]
            cell.configure(title: data.title, icon: data.icon,
                           color: data.color, isSwitch: data.isSwitch)
            return cell

        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LogoutCell",
                                                          for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            let lbl = UILabel(frame: cell.contentView.bounds)
            lbl.text             = "Log Out"
            lbl.textColor        = .systemRed
            lbl.textAlignment    = .center
            lbl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            cell.contentView.addSubview(lbl)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        switch indexPath.section {
        case 2:
            // Section 2, item 0 = Streak card, item 1 = Badges card
            indexPath.item == 0 ? openStreakDetails() : openBadges()
        case 4:
            handleLogout()
        default:
            break
        }
    }
}

// MARK: - LevelCellDelegate

extension ProfileViewController: LevelCellDelegate {
    func didTapXPCard() {
        openXPInfo()
    }
}

// MARK: - EditProfileDelegate

extension ProfileViewController: EditProfileDelegate {
    func didUpdateProfile(name: String, image: UIImage?) {
        userName = name
        if let img = image { userImage = img }
        collectionView.reloadSections(IndexSet(integer: 0))
    }
}
