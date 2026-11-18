import UIKit
import Supabase
import SafariServices

struct UserProfile: Decodable {
    let username: String
    let avatar_url: String?
}

// MARK: - Duolingo-Inspired Hero Profile Cell
class DuolingoHeroProfileCell: UICollectionViewCell {
    static let reuseID = "DuolingoHeroProfileCell"

    private let cardContainer = UIView()
    private let bannerView = UIView()
    let avatarImageView = UIImageView()
    private let editBadgeButton = UIButton(type: .system)
    let nameLabel = UILabel()
    private let categoryBadgeView = UIView()
    let categoryLabel = UILabel()
    private let editProfileButton = UIButton(type: .system)

    var didTapEdit: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.layer.borderColor = UIColor.secondarySystemGroupedBackground.cgColor
        editBadgeButton.layer.borderColor = UIColor.secondarySystemGroupedBackground.cgColor
    }

    private func setupViews() {
        contentView.addSubview(cardContainer)
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.layer.cornerRadius = 20
        cardContainer.clipsToBounds = true
        cardContainer.backgroundColor = .secondarySystemGroupedBackground

        cardContainer.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 43
        avatarImageView.layer.borderWidth = 3.5
        avatarImageView.layer.borderColor = UIColor.secondarySystemGroupedBackground.cgColor
        avatarImageView.backgroundColor = .systemGray5
        avatarImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleEdit))
        avatarImageView.addGestureRecognizer(tap)
        cardContainer.addSubview(avatarImageView)

        editBadgeButton.translatesAutoresizingMaskIntoConstraints = false
        var editCfg = UIButton.Configuration.filled()
        editCfg.image = UIImage(systemName: "pencil", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold))
        editCfg.baseBackgroundColor = .systemBlue
        editCfg.baseForegroundColor = .white
        editCfg.cornerStyle = .capsule
        editBadgeButton.configuration = editCfg
        editBadgeButton.layer.borderWidth = 2
        editBadgeButton.layer.borderColor = UIColor.secondarySystemGroupedBackground.cgColor
        editBadgeButton.clipsToBounds = true
        editBadgeButton.addTarget(self, action: #selector(handleEdit), for: .touchUpInside)
        cardContainer.addSubview(editBadgeButton)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.85
        cardContainer.addSubview(nameLabel)

        categoryBadgeView.translatesAutoresizingMaskIntoConstraints = false
        categoryBadgeView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.12)
        categoryBadgeView.layer.cornerRadius = 11
        categoryBadgeView.clipsToBounds = true
        cardContainer.addSubview(categoryBadgeView)

        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        categoryLabel.textColor = .secondaryLabel
        categoryLabel.textAlignment = .center
        categoryBadgeView.addSubview(categoryLabel)

        editProfileButton.translatesAutoresizingMaskIntoConstraints = false
        var btnCfg = UIButton.Configuration.tinted()
        btnCfg.title = "Edit Profile"
        btnCfg.image = UIImage(systemName: "pencil")
        btnCfg.imagePadding = 6
        btnCfg.baseBackgroundColor = .systemBlue
        btnCfg.baseForegroundColor = .systemBlue
        btnCfg.cornerStyle = .capsule
        btnCfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }
        editProfileButton.configuration = btnCfg
        editProfileButton.addTarget(self, action: #selector(handleEdit), for: .touchUpInside)
        cardContainer.addSubview(editProfileButton)

        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            bannerView.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            bannerView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
            bannerView.heightAnchor.constraint(equalToConstant: 56),

            avatarImageView.centerXAnchor.constraint(equalTo: cardContainer.centerXAnchor),
            avatarImageView.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: 14),
            avatarImageView.widthAnchor.constraint(equalToConstant: 86),
            avatarImageView.heightAnchor.constraint(equalToConstant: 86),

            editBadgeButton.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 2),
            editBadgeButton.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 2),
            editBadgeButton.widthAnchor.constraint(equalToConstant: 26),
            editBadgeButton.heightAnchor.constraint(equalToConstant: 26),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -16),

            categoryBadgeView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            categoryBadgeView.centerXAnchor.constraint(equalTo: cardContainer.centerXAnchor),
            categoryBadgeView.leadingAnchor.constraint(greaterThanOrEqualTo: cardContainer.leadingAnchor, constant: 16),
            categoryBadgeView.trailingAnchor.constraint(lessThanOrEqualTo: cardContainer.trailingAnchor, constant: -16),
            categoryBadgeView.heightAnchor.constraint(equalToConstant: 22),

            categoryLabel.leadingAnchor.constraint(equalTo: categoryBadgeView.leadingAnchor, constant: 10),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryBadgeView.trailingAnchor, constant: -10),
            categoryLabel.centerYAnchor.constraint(equalTo: categoryBadgeView.centerYAnchor),

            editProfileButton.topAnchor.constraint(equalTo: categoryBadgeView.bottomAnchor, constant: 12),
            editProfileButton.centerXAnchor.constraint(equalTo: cardContainer.centerXAnchor),
            editProfileButton.heightAnchor.constraint(equalToConstant: 32),
            editProfileButton.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -14)
        ])
    }

    @objc private func handleEdit() {
        didTapEdit?()
    }

    func configure(name: String, email: String, category: String, image: UIImage?) {
        nameLabel.text = name
        let displayCat = category.isEmpty ? email : "🎓 \(category)"
        categoryLabel.text = displayCat
        if let img = image {
            avatarImageView.image = img
        } else {
            avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")?
                .withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        }
    }
}

// MARK: - Modern Section Header View
class ProfileSectionHeaderView: UICollectionReusableView {
    static let reuseID = "ProfileSectionHeaderView"
    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            titleLabel.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

class ProfileViewController: UIViewController {

    var collectionView: UICollectionView!
    private var didPerformInitialScroll = false

    var userName: String = "Loading..."
    var userEmail: String = "Loading..."
    var userImage: UIImage? = UIImage(systemName: "person.crop.circle.fill")?
        .withTintColor(.systemGray3, renderingMode: .alwaysOriginal)

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
            self?.collectionView.reloadData()
        }

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let xImage = UIImage(systemName: "multiply", withConfiguration: config)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: xImage, style: .plain, target: self, action: #selector(handleDismiss))

        fetchUserData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didPerformInitialScroll {
            didPerformInitialScroll = true
            collectionView.setContentOffset(CGPoint(x: 0, y: -collectionView.adjustedContentInset.top), animated: false)
        }
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

                        var resolvedName = profile.username
                        if resolvedName == "New Student" || resolvedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            if let metaName = user.userMetadata["full_name"]?.value as? String, !metaName.isEmpty {
                                resolvedName = metaName
                            } else if let metaName = user.userMetadata["name"]?.value as? String, !metaName.isEmpty {
                                resolvedName = metaName
                            } else if let prefix = user.email?.components(separatedBy: "@").first?.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "_", with: " ").capitalized, !prefix.isEmpty {
                                resolvedName = prefix
                            } else {
                                resolvedName = "Student"
                            }
                            _ = try? await supabase.from("profiles").update(["username": resolvedName]).eq("id", value: userId).execute()
                        }

                        DispatchQueue.main.async {
                            self.userName = resolvedName
                            self.collectionView.reloadData()
                        }

                        if let avatarString = profile.avatar_url, !avatarString.isEmpty {
                            let cacheBuster = "?v=\(Date().timeIntervalSince1970)"
                            if let url = URL(string: avatarString + cacheBuster) {
                                downloadProfileImage(from: url)
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.userImage = UIImage(systemName: "person.crop.circle.fill")?
                                    .withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
                                self.collectionView.reloadData()
                            }
                        }
                    } catch {
                        let defaultName = user.email?.components(separatedBy: "@").first?.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "_", with: " ").capitalized ?? "Student"
                        let resolvedName = user.userMetadata["full_name"]?.value as? String ?? (user.userMetadata["name"]?.value as? String ?? defaultName)
                        DispatchQueue.main.async {
                            self.userName = resolvedName
                            self.collectionView.reloadData()
                        }
                    }
                } catch {
                    print("❌ Error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.userName = "User Not Found"
                        self.userEmail = "Offline"
                        self.collectionView.reloadData()
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
                        self.collectionView.reloadData()
                    }
                }
            } catch {
                print("Failed to download image: \(error.localizedDescription)")
            }
        }
    }

    func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.contentInsetAdjustmentBehavior = .always

        collectionView.register(DuolingoHeroProfileCell.self, forCellWithReuseIdentifier: DuolingoHeroProfileCell.reuseID)
        collectionView.register(UINib(nibName: "LevelCell", bundle: nil), forCellWithReuseIdentifier: "LevelCell")
        collectionView.register(UINib(nibName: "StatCardCell", bundle: nil), forCellWithReuseIdentifier: "StatCardCell")
        collectionView.register(UINib(nibName: "SettingsCell", bundle: nil), forCellWithReuseIdentifier: "SettingsCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "LogoutCell")

        collectionView.register(
            ProfileSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ProfileSectionHeaderView.reuseID
        )

        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, env) -> NSCollectionLayoutSection? in
            if sectionIndex == 0 {
                // Hero Profile Card
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(224)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(224)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 14, trailing: 16)
                return section

            } else if sectionIndex == 1 {
                // Level Progress Card
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80)))
                let section = NSCollectionLayoutSection(group: NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item]))
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)

                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(28)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                return section

            } else if sectionIndex == 2 {
                // Overview 2x2 Stats Grid
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(86)))
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(86)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 16, trailing: 12)

                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(28)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                return section

            } else if sectionIndex == 3 {
                // Preferences & Support (Grouped Card)
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)

                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(28)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                return section

            } else {
                // Account Actions (Log Out & Delete Account)
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 12
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 40, trailing: 16)

                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(28)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
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

    private func handleDeleteAccount() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to permanently delete your account? All your study materials, progress, streak, and XP will be deleted. This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Forever", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }

            let loadingAlert = UIAlertController(title: nil, message: "Deleting account...", preferredStyle: .alert)
            let indicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            indicator.hidesWhenStopped = true
            indicator.startAnimating()
            indicator.style = .medium
            loadingAlert.view.addSubview(indicator)
            self.present(loadingAlert, animated: true)

            Task {
                do {
                    let user = try await supabase.auth.session.user
                    let userId = user.id.uuidString

                    // 1. Delete user profile record from Supabase
                    _ = try? await supabase.from("profiles").delete().eq("id", value: userId).execute()

                    // 2. Sign out auth session
                    try? await supabase.auth.signOut()

                    // 3. Clear local device storage
                    self.resetLocalData()

                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true) {
                            self.transitionToLoginScreen()
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true) {
                            let errAlert = UIAlertController(
                                title: "Error",
                                message: "Failed to delete account: \(error.localizedDescription)",
                                preferredStyle: .alert
                            )
                            errAlert.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(errAlert, animated: true)
                        }
                    }
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
        return section == 2 ? 4 : (section == 3 ? settingsData.count : (section == 4 ? 2 : 1))
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else { return UICollectionReusableView() }
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: ProfileSectionHeaderView.reuseID,
            for: indexPath
        ) as! ProfileSectionHeaderView

        switch indexPath.section {
        case 1: header.titleLabel.text = "LEVEL PROGRESS"
        case 2: header.titleLabel.text = "OVERVIEW"
        case 3: header.titleLabel.text = "PREFERENCES & SUPPORT"
        case 4: header.titleLabel.text = "ACCOUNT"
        default: header.titleLabel.text = ""
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DuolingoHeroProfileCell.reuseID, for: indexPath) as! DuolingoHeroProfileCell
            let category = UserDefaults.standard.string(forKey: "user_subcategory") ?? UserDefaults.standard.string(forKey: "user_category") ?? ""
            cell.configure(name: self.userName, email: self.userEmail, category: category, image: self.userImage)
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
            let manager = ProgressDataManager.shared
            if indexPath.item == 0 {
                let streak = manager.currentStreak
                let streakSuffix = streak == 1 ? "Day" : "Days"
                cell.configure(title: "Streak", value: "\(streak) \(streakSuffix)", icon: "flame.fill", color: .systemOrange)
            } else if indexPath.item == 1 {
                cell.configure(title: "Total XP", value: "\(manager.totalXP) XP", icon: "bolt.fill", color: .systemYellow)
            } else if indexPath.item == 2 {
                cell.configure(title: "Current Level", value: "Level \(manager.userLevel)", icon: "shield.fill", color: .systemBlue)
            } else {
                let earnedCount = Badging.allMilestones.filter { $0.isEarned }.count
                cell.configure(title: "Badges", value: "\(earnedCount) Earned", icon: "trophy.fill", color: .systemPurple)
            }
            applyCardStyle(to: cell)
            return cell

        } else if indexPath.section == 3 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            let data = settingsData[indexPath.item]
            cell.configure(title: data.title, icon: data.icon, color: data.color, isSwitch: data.isSwitch)

            // Grouped card styling — round corners on first/last cells
            let totalItems = settingsData.count
            cell.layer.cornerRadius = 0
            cell.layer.maskedCorners = []
            cell.clipsToBounds = true

            if totalItems == 1 {
                cell.layer.cornerRadius = 14
                cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else if indexPath.item == 0 {
                cell.layer.cornerRadius = 14
                cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            } else if indexPath.item == totalItems - 1 {
                cell.layer.cornerRadius = 14
                cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            }

            // Hide separator on the last cell
            cell.separatorView?.isHidden = (indexPath.item == totalItems - 1)

            return cell

        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LogoutCell", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.layer.cornerRadius = 14
            cell.clipsToBounds = true
            let lbl = UILabel(frame: cell.contentView.bounds)
            lbl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            if indexPath.item == 0 {
                lbl.text = "Log Out"
                lbl.textColor = .systemBlue
            } else {
                lbl.text = "Delete Account"
                lbl.textColor = .systemRed
            }
            lbl.textAlignment = .center
            lbl.font = .systemFont(ofSize: 17, weight: .semibold)
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
            } else if indexPath.item == 1 || indexPath.item == 2 {
                let xpVC = XPInfoSheetViewController()
                navigationController?.pushViewController(xpVC, animated: true)
            } else if indexPath.item == 3 {
                let badgesVC = EarnedBadgesViewController()
                navigationController?.pushViewController(badgesVC, animated: true)
            }

        } else if indexPath.section == 3 {
            // "Privacy & Security" (item 2) or "Help & Support" (item 3)
            if indexPath.item == 2 || indexPath.item == 3 {
                if let url = URL(string: "https://reviseq.netlify.app") {
                    let safariVC = SFSafariViewController(url: url)
                    present(safariVC, animated: true)
                }
            }
        } else if indexPath.section == 4 {
            if indexPath.item == 0 {
                handleLogout()
            } else {
                handleDeleteAccount()
            }
        }
    }
}

extension ProfileViewController: EditProfileDelegate {
    func didUpdateProfile(name: String, image: UIImage?) {
        self.userName = name
        if let img = image { self.userImage = img }
        collectionView.reloadData()
    }
}
