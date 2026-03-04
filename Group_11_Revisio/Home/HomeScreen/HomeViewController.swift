//
//  HomeViewController.swift
//  Group_11_Revisio
//

import UIKit
import UniformTypeIdentifiers
import Supabase // ✅ Added Supabase Import

// MARK: - Supporting Structures
struct GameItem: Hashable, Sendable {
    let title: String
    let imageAsset: String
}

enum HomeSection: Int, CaseIterable {
    case hero = 0
    case uploadContent
    case continueLearning
    case sideQuests
    case quickGames
}

// MARK: - Constants
let hiAlexCellID = "HiAlexCellID"
let uploadContentCellID = "UploadContentCellID"
let continueLearningCellID = "ContinueLearningCellID"
let quickGamesCellID = "QuickGamesCellID"
let sideQuestsCellID = "SideQuestsCollectionViewCell"
let headerID = "HeaderID"

// Segue Identifiers
let showConnectionsSegueID = "ConnectionsSegue"
let showWordFillSegueID = "ShowWordFillSegue"
let showUploadConfirmationSegueID = "ShowUploadConfirmation"
let showChatSegueID = "ShowChatSegue"
let showNotesDetailSegueID = "ShowNotesDetail"
let showQuizStartSegueID = "ShowQuizStart"
let showSubjectDetailSegueID = "ShowSubjectDetail"
let showDailyChallengeSegueID = "ShowDailyChallenge"
let showFlashcardsSegueID = "ShowFlashcardsSegue"
let showCheatsheetSegueID = "ShowCheatsheet"

protocol QuickGamesCellDelegate: AnyObject {
    func didSelectQuickGame(gameTitle: String)
}

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - Properties
    var heroData: [ContentItem] = []
    var uploadItems: [ContentItem] = []
    var learningItems: [ContentItem] = []
    var gameItems: [GameItem] = []
    
    // Side Quests Data
    var sideQuests: [SideQuest] = []
    var completedQuests: [SideQuest] = [] // For History
    
    // ✅ NEW Keys to ensure a completely fresh save state
    private let activeQuestsKey = "Exora_ActiveQuests_v3"
    private let completedQuestsKey = "Exora_CompletedQuests_v3"
    
    var isLearningExpanded: Bool = false
    
    // ✅ User Data Properties
    var userName: String = "User" // Default until fetched
    var userProfileImage: UIImage? = UIImage(named: "profile_placeholder")
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Floating AI Button
    private let aiFloatingButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        guard let originalImage = UIImage(named: "exora_icon") else {
            btn.setImage(UIImage(systemName: "sparkles"), for: .normal)
            return btn
        }
        
        let targetSize = CGSize(width: 45, height: 45)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .label
        config.cornerStyle = .capsule
        config.image = resizedImage.withRenderingMode(.alwaysOriginal)
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        btn.configuration = config
        
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 6
        
        return btn
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupCollectionView()
        setupProfileIcon() // Initial setup with placeholder
        setupFloatingAIButton()
        
        // ✅ Fetch Real Data from Supabase
        fetchSupabaseUserData()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        // ✅ 2. Listen for the update message
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUserData), name: NSNotification.Name("ProfileDidUpdate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataUpdate), name: .didUpdateStudyMaterials, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshXPUI), name: .xpDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showLevelUpCelebration), name: NSNotification.Name("UserLeveledUp"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecentLearningData()
        // Refresh data when returning to home in case profile was edited
        fetchSupabaseUserData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Supabase Data Fetching
    private func fetchSupabaseUserData() {
        Task {
            do {
                let user = try await supabase.auth.session.user
                let userId = user.id.uuidString
                
                let profile: UserProfile = try await supabase
                    .from("profiles")
                    .select("username, avatar_url")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                DispatchQueue.main.async {
                    self.userName = profile.username
                    // Reload hero section to update Greeting
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
                // In fetchSupabaseUserData...
                if let avatarString = profile.avatar_url {
                    // ✅ Force a fresh download
                    let cacheBuster = "?v=\(Date().timeIntervalSince1970)"
                    if let url = URL(string: avatarString + cacheBuster) {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let downloadedImage = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.userProfileImage = downloadedImage
                                self.setupProfileIcon() // Refresh bar button with real image
                            }
                        }
                    }
                }
            
            } catch {
                print("Home Fetch Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func handleDataUpdate() {
        loadRecentLearningData()
    }
    
    @objc func refreshXPUI() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc private func refreshUserData() {
        fetchSupabaseUserData() // This re-downloads the latest name and image
    }
    
    @objc func showLevelUpCelebration() {
        let newLevel = ProgressDataManager.shared.currentLevel
        let alert = UIAlertController(title: "🎉 LEVEL UP!", message: "Congratulations! You've reached Level \(newLevel). Keep conquering your studies!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Awesome!", style: .default))
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        self.present(alert, animated: true)
    }
    
    // MARK: - Persistence (Save & Load Tasks)
    private func loadQuests() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: activeQuestsKey),
           let saved = try? JSONDecoder().decode([SideQuest].self, from: data) {
            self.sideQuests = saved
        } else {
            self.sideQuests = []
        }
        
        if let data = defaults.data(forKey: completedQuestsKey),
           let saved = try? JSONDecoder().decode([SideQuest].self, from: data) {
            self.completedQuests = saved
        } else {
            self.completedQuests = []
        }
    }

    private func saveQuests() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(sideQuests) {
            defaults.set(data, forKey: activeQuestsKey)
        }
        if let data = try? JSONEncoder().encode(completedQuests) {
            defaults.set(data, forKey: completedQuestsKey)
        }
        defaults.synchronize()
    }
    
    // MARK: - Data Fetching
        func loadRecentLearningData() {
            let allTopics = DataManager.shared.getAllRecentTopics()
            
            // ✅ PRO FIX: Filter the data!
            let incompleteTasks = allTopics.filter { topic in
                let typeLower = topic.materialType.lowercased()
                
                // 1. Only show interactive materials (No PDFs or standard Notes)
                let isInteractive = typeLower.contains("quiz") || typeLower.contains("flashcard")
                
                // 2. Check if it is incomplete
                // ⚠️ Note: Adjust this line based on how your 'Topic' model actually tracks progress!
                // If you don't have a progress variable yet, just use 'true' for now.
                let isNotFinished = true // Example: topic.completionPercentage < 100
                
                return isInteractive && isNotFinished
            }
            
            // Grab only the top 5 incomplete interactive tasks
            let recentTopics = Array(incompleteTasks.prefix(5))
            
            // Map them to your ContentItem array
            self.learningItems = recentTopics.map { topic in
                var type = topic.materialType
                if type == "Flashcards" { type = "Flashcard" } // Map Plural to Singular
                return ContentItem(title: topic.name, iconName: "doc.text", itemType: type)
            }
            
            // Refresh the UI
            DispatchQueue.main.async { self.collectionView.reloadData() }
        }
    
    // MARK: - Setup
    private func setupData() {
        heroData = [ContentItem(title: "Hi Alex !", iconName: "", itemType: "Greeting")]
        uploadItems = [
            ContentItem(title: "Big Data.pdf", iconName: "doc.fill", itemType: "PDF"),
            ContentItem(title: "Data Structures- Trees.com", iconName: "link", itemType: "Link"),
            ContentItem(title: "New File", iconName: "plus.circle.fill", itemType: "AddButton")
        ]
        learningItems = []
        gameItems = [
            GameItem(title: "", imageAsset: "Gemini_Generated_Image_p66f9tp66f9tp66f-removebg-preview"),
            GameItem(title: "", imageAsset: "Gemini_Generated_Image_y6xx8iy6xx8iy6xx-removebg-preview")
        ]
        
        loadQuests()
    }
    
    private func setupCollectionView() {
        registerCustomCells()
        collectionView.collectionViewLayout = generateLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.keyboardDismissMode = .onDrag
    }
    
    func registerCustomCells() {
        collectionView.register(UINib(nibName: "HiAlexCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: hiAlexCellID)
        collectionView.register(UINib(nibName: "UploadContentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: uploadContentCellID)
        collectionView.register(UINib(nibName: "ContinueLearningCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: continueLearningCellID)
        collectionView.register(UINib(nibName: "QuickGamesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: quickGamesCellID)
        collectionView.register(UINib(nibName: "SideQuestsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: sideQuestsCellID)
        collectionView.register(UINib(nibName: "HeaderViewCollectionReusableView", bundle: nil),
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: headerID)
    }
    
    // MARK: - Floating AI Button
    private func setupFloatingAIButton() {
        view.addSubview(aiFloatingButton)
        NSLayoutConstraint.activate([
            aiFloatingButton.widthAnchor.constraint(equalToConstant: 60),
            aiFloatingButton.heightAnchor.constraint(equalToConstant: 60),
            aiFloatingButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            aiFloatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        aiFloatingButton.addTarget(self, action: #selector(didTapAIButton), for: .touchUpInside)
    }
    
    @objc func didTapAIButton() {
        UIView.animate(withDuration: 0.1, animations: {
            self.aiFloatingButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.aiFloatingButton.transform = .identity
            } completion: { _ in
                self.performSegue(withIdentifier: showChatSegueID, sender: self)
            }
        }
    }
    
    // MARK: - Profile Icon
    private func setupProfileIcon() {
        let button = UIButton(type: .custom)
        button.setImage(userProfileImage, for: .normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.imageView?.contentMode = .scaleAspectFill
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(profileButtonTapped(_:)), for: .touchUpInside)
        
        let barItem = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barItem
    }
    
    @IBAction func profileButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "showProfileSegue", sender: nil)
    }
    
    // MARK: - Navigation Preparation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showUploadConfirmationSegueID {
            if let destinationVC = segue.destination as? UploadConfirmationViewController, let filePath = sender as? String {
                destinationVC.incomingDataPath = filePath
            }
        }
        else if segue.identifier == showNotesDetailSegueID {
            if let destVC = segue.destination as? NotesViewController, let topic = sender as? Topic {
                destVC.currentTopic = topic
                destVC.parentSubjectName = topic.parentSubjectName
            }
        }
        else if segue.identifier == showQuizStartSegueID {
            if let destVC = segue.destination as? QuizStartViewController, let topic = sender as? Topic {
                destVC.currentTopic = topic
                destVC.parentSubject = topic.parentSubjectName
                destVC.quizSourceName = topic.name
            }
        }
        else if segue.identifier == showSubjectDetailSegueID {
            if let destVC = segue.destination as? SubjectViewController, let subjectName = sender as? String {
                destVC.selectedSubject = subjectName
            }
        }
        else if segue.identifier == showFlashcardsSegueID {
            if let destVC = segue.destination as? FlashcardViewController, let topic = sender as? Topic {
                destVC.currentTopic = topic
                destVC.parentSubjectName = topic.parentSubjectName
            } else if let destVC = segue.destination as? FlashcardsViewController, let topic = sender as? Topic {
                destVC.currentTopic = topic
                destVC.parentSubjectName = topic.parentSubjectName
            }
        }
        else if segue.identifier == showCheatsheetSegueID {
            if let destVC = segue.destination as? CheatsheetViewController, let topic = sender as? Topic {
                destVC.currentTopic = topic
                destVC.parentSubjectName = topic.parentSubjectName
            }
        }
    }
    
    // MARK: - Layout Configuration
    func generateLayout() -> UICollectionViewLayout {
        let horizontalPadding: CGFloat = 16
        let verticalSpacing: CGFloat = 16
        
        return UICollectionViewCompositionalLayout { [self] sectionIndex, env in
            let sectionType = HomeSection.allCases[sectionIndex]
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            let itemWidth = NSCollectionLayoutDimension.fractionalWidth(1.0)
            
            switch sectionType {
            case .hero:
                let size = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(138))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                return section
                
            case .sideQuests:
                let size = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(300))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                section.boundarySupplementaryItems = [headerItem]
                return section
                
            case .uploadContent:
                let size = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(156))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                return section
                
            case .continueLearning:
                let rowHeight: CGFloat = 75
                let countToShow = isLearningExpanded ? learningItems.count : min(learningItems.count, 2)
                let totalHeight = CGFloat(max(countToShow, 1)) * rowHeight
                
                let size = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .absolute(totalHeight))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: 5, trailing: horizontalPadding)
                section.boundarySupplementaryItems = [headerItem]
                return section
                
            case .quickGames:
                let size = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(130))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                section.boundarySupplementaryItems = [headerItem]
                return section
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int { return HomeSection.allCases.count }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = HomeSection.allCases[section]
        switch sectionType {
        case .hero: return heroData.count
        default: return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = HomeSection.allCases[indexPath.section]
        
        switch sectionType {
        case .hero:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: hiAlexCellID, for: indexPath) as! HiAlexCollectionViewCell
            // ✅ Dynamically Update the Greeting with the real Username
            cell.delegate = self
            return cell
            
        case .sideQuests:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sideQuestsCellID, for: indexPath) as! SideQuestsCollectionViewCell
            cell.configure(with: self.sideQuests)
            cell.delegate = self
            return cell
            
        case .uploadContent:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: uploadContentCellID, for: indexPath) as! UploadContentCollectionViewCell
            cell.delegate = self
            cell.configure(with: uploadItems)
            return cell
            
        case .continueLearning:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: continueLearningCellID, for: indexPath) as! ContinueLearningCollectionViewCell
            let itemsToShow = isLearningExpanded ? learningItems : Array(learningItems.prefix(2))
            cell.configure(with: itemsToShow)
            cell.delegate = self
            return cell
            
        case .quickGames:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: quickGamesCellID, for: indexPath) as! QuickGamesCollectionViewCell
            cell.delegate = self
            if gameItems.count >= 2 { cell.configure(with: gameItems[0], and: gameItems[1]) }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerID, for: indexPath) as! HeaderViewCollectionReusableView
        let sectionType = HomeSection.allCases[indexPath.section]
        
        if sectionType == .sideQuests {
            headerView.isHidden = false
            headerView.configureHeader(with: "Daily Side Quests", showViewAll: false, section: indexPath.section)
            headerView.delegate = nil
            return headerView
        }
        
        if sectionType == .continueLearning {
            headerView.isHidden = false
            headerView.configureHeader(with: "Continue Learning", showViewAll: true, section: indexPath.section, isExpanded: isLearningExpanded)
            headerView.delegate = self
            return headerView
        }
        
        if sectionType == .quickGames {
            headerView.isHidden = false
            headerView.configureHeader(with: "Quick Games", showViewAll: false, section: indexPath.section)
            headerView.delegate = nil
            return headerView
        }
        
        headerView.isHidden = true
        return headerView
    }
}

// MARK: - Header Delegate
extension HomeViewController: HeaderViewDelegate {
    func didTapViewAll(in section: Int) {
        isLearningExpanded.toggle()
        collectionView.reloadSections(IndexSet(integer: section))
    }
}

// MARK: - Side Quests Delegate
extension HomeViewController: SideQuestDelegate {
    func didUpdateQuests(_ quests: [SideQuest]) {
        self.sideQuests = quests
        saveQuests()
        
        if let sectionIndex = HomeSection.allCases.firstIndex(of: .sideQuests) {
            collectionView.reloadSections(IndexSet(integer: sectionIndex))
        }
    }
    
    func didCompleteQuest(_ quest: SideQuest) {
        var completedTask = quest
        completedTask.isCompleted = true
        self.completedQuests.insert(completedTask, at: 0)
        ProgressDataManager.shared.totalQuestsCompleted += 1
        saveQuests()
    }
    
    func didTapHistory() {
        let historyVC = QuestHistoryViewController()
        historyVC.history = self.completedQuests
        if let nav = navigationController {
            nav.pushViewController(historyVC, animated: true)
        } else {
            present(historyVC, animated: true)
        }
    }
    
    func didEarnXP(amount: Int, sourceView: UIView) {
        let frame = sourceView.convert(sourceView.bounds, to: self.view)
        let lbl = UILabel(frame: frame)
        lbl.text = "+\(amount) XP"
        lbl.font = .boldSystemFont(ofSize: 20)
        lbl.textColor = .systemYellow
        self.view.addSubview(lbl)
        
        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseOut, animations: {
            lbl.transform = CGAffineTransform(translationX: 0, y: -60)
            lbl.alpha = 0
        }) { _ in
            lbl.removeFromSuperview()
        }
        Task { await RevisioManager.shared.earnXP(amount: amount, reason: "Side Quest Done") }
    }
}

// MARK: - Continue Learning Delegate
extension HomeViewController: ContinueLearningCellDelegate {
    func didSelectLearningItem(_ item: ContentItem) {
        let allTopics = DataManager.shared.getAllRecentTopics()
        
        guard let realTopic = allTopics.first(where: { topic in
            let nameMatches = (topic.name == item.title)
            let topicType = topic.materialType.lowercased()
            let itemType = item.itemType.lowercased()
            let typeMatches = topicType.contains(itemType) || itemType.contains(topicType)
            return nameMatches && typeMatches
        }) else { return }
        
        let typeLower = realTopic.materialType.lowercased()
        if typeLower.contains("quiz") { performSegue(withIdentifier: showQuizStartSegueID, sender: realTopic) }
        else if typeLower.contains("flashcard") { performSegue(withIdentifier: showFlashcardsSegueID, sender: realTopic) }
        else if typeLower.contains("cheatsheet") { performSegue(withIdentifier: showCheatsheetSegueID, sender: realTopic) }
        else { performSegue(withIdentifier: showNotesDetailSegueID, sender: realTopic) }
    }
}

// MARK: - Quick Games Delegate
extension HomeViewController: QuickGamesCellDelegate {
    func didSelectQuickGame(gameTitle: String) {
        let segueID = (gameTitle == "Word Fill") ? showWordFillSegueID : showConnectionsSegueID
        performSegue(withIdentifier: segueID, sender: nil)
    }
}

// MARK: - Upload Delegate & Document Picker
extension HomeViewController: UploadContentCellDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func navigateToConfirmation(with contentPath: String) { performSegue(withIdentifier: showUploadConfirmationSegueID, sender: contentPath) }
    
    func uploadCellDidTapDocument(_ cell: UploadContentCollectionViewCell) {
        let types: [UTType] = [.pdf, .text, .image, .data, .content]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func uploadCellDidTapMedia(_ cell: UploadContentCollectionViewCell) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func uploadCellDidTapLink(_ cell: UploadContentCollectionViewCell) { showLinkInputAlert() }
    
    func uploadCellDidTapText(_ cell: UploadContentCollectionViewCell) {
        let noteVC = NoteInputViewController()
        noteVC.onSave = { [weak self] text in self?.navigateToConfirmation(with: text) }
        let nav = UINavigationController(rootViewController: noteVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
    
    private func showLinkInputAlert() {
        let alert = UIAlertController(title: "Add Resource Link", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "https://..." }
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in
            guard let text = alert.textFields?.first?.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            let lower = text.lowercased()
            if (lower.hasPrefix("http://") || lower.hasPrefix("https://")), let url = URL(string: text), UIApplication.shared.canOpenURL(url) {
                self.navigateToConfirmation(with: text)
            } else {
                let errorAlert = UIAlertController(title: "Invalid Link", message: "URL must start with http:// or https://", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in self.showLinkInputAlert() })
                self.present(errorAlert, animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        navigateToConfirmation(with: url.path)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            guard let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.8) else { return }
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "Media_\(Int(Date().timeIntervalSince1970)).jpg"
            let fileURL = tempDir.appendingPathComponent(fileName)
            do {
                try data.write(to: fileURL)
                self.navigateToConfirmation(with: fileURL.path)
            } catch { print("Error saving image: \(error)") }
        }
    }
}

// MARK: - Note Input Controller
class NoteInputViewController: UIViewController {
    var onSave: ((String) -> Void)?
    private let textView = UITextView()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "New Note"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(saveTapped))
        textView.font = .systemFont(ofSize: 18)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
        textView.becomeFirstResponder()
    }
    @objc private func cancelTapped() { dismiss(animated: true) }
    @objc private func saveTapped() {
        guard let text = textView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onSave?(text)
        dismiss(animated: true)
    }
}

// MARK: - Daily Challenge Delegate
extension HomeViewController: HiAlexCellDelegate {
    func didTapPlayNow() { performSegue(withIdentifier: showDailyChallengeSegueID, sender: nil) }
}
