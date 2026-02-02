//
//  HomeViewController.swift
//  Group_11_Revisio
//

import UIKit
import UniformTypeIdentifiers

// MARK: - Supporting Structures
struct GameItem: Hashable, Sendable {
    let title: String
    let imageAsset: String
}

// ✅ Updated Enum Order
enum HomeSection: Int, CaseIterable {
    case hero = 0
    case uploadContent
    case continueLearning
    case sideQuests // 🆕 Placed right after Hero
    case quickGames
}

// MARK: - Constants
let hiAlexCellID = "HiAlexCellID"
let uploadContentCellID = "UploadContentCellID"
let continueLearningCellID = "ContinueLearningCellID"
let quickGamesCellID = "QuickGamesCellID"
let sideQuestsCellID = "SideQuestsCollectionViewCell" // 🆕
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
let showFlashcardsSegueID = "ShowFlashcardsSegue" // 🆕

protocol QuickGamesCellDelegate: AnyObject {
    func didSelectQuickGame(gameTitle: String)
}

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - Properties
    var heroData: [ContentItem] = []
    var uploadItems: [ContentItem] = []
    var learningItems: [ContentItem] = []
    var gameItems: [GameItem] = []
    
    // 🆕 Side Quests Data
    var sideQuests: [SideQuest] = []
    var completedQuests: [SideQuest] = [] // For History
    
    var isLearningExpanded: Bool = false
    
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
        setupProfileIcon()
        setupFloatingAIButton()
    }
    
    // MARK: - Setup
    private func setupData() {
        heroData = [ContentItem(title: "Hi Alex !", iconName: "", itemType: "Greeting")]
        
        uploadItems = [
            ContentItem(title: "Big Data.pdf", iconName: "doc.fill", itemType: "PDF"),
            ContentItem(title: "Data Structures- Trees.com", iconName: "link", itemType: "Link"),
            ContentItem(title: "New File", iconName: "plus.circle.fill", itemType: "AddButton")
        ]
        
        learningItems = [
            ContentItem(title: "Physics Ch 4 Quiz", iconName: "checkmark.circle.fill", itemType: "Quiz"),
            ContentItem(title: "Bio Definitions", iconName: "rectangle.stack", itemType: "Flashcard"),
            ContentItem(title: "Area under functions", iconName: "book.fill", itemType: "Topic"), // 🆕
            ContentItem(title: "History Notes", iconName: "doc.text.fill", itemType: "Notes")
        ]
        
        gameItems = [
            GameItem(title: "", imageAsset: "Gemini_Generated_Image_p66f9tp66f9tp66f-removebg-preview"),
            GameItem(title: "", imageAsset: "Gemini_Generated_Image_y6xx8iy6xx8iy6xx-removebg-preview")
        ]
        
        // Initial Side Quests (No Difficulty)
        sideQuests = [
            SideQuest(title: "Read Chapter 1"),
            SideQuest(title: "Complete Assignment")
        ]
    }
    
    private func setupCollectionView() {
        registerCustomCells()
        collectionView.collectionViewLayout = generateLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .never
    }
    
    func registerCustomCells() {
        collectionView.register(UINib(nibName: "HiAlexCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: hiAlexCellID)
        collectionView.register(UINib(nibName: "UploadContentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: uploadContentCellID)
        collectionView.register(UINib(nibName: "ContinueLearningCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: continueLearningCellID)
        collectionView.register(UINib(nibName: "QuickGamesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: quickGamesCellID)
        
        // 🆕 Register Side Quests Cell
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
        if let image = UIImage(named: "profile_placeholder") {
            button.setImage(image, for: .normal)
        } else {
            button.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
        }
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
            if let destinationVC = segue.destination as? UploadConfirmationViewController,
               let filename = sender as? String {
                destinationVC.uploadedContentName = filename
            }
        }
        
        if segue.identifier == showNotesDetailSegueID {
            if let destVC = segue.destination as? NotesViewController,
               let topic = sender as? Topic {
                destVC.currentTopic = topic
                destVC.parentSubjectName = topic.parentSubjectName
            }
        }
        
        if segue.identifier == showQuizStartSegueID {
            if let destVC = segue.destination as? QuizStartViewController,
               let topic = sender as? Topic {
                destVC.currentTopic = topic
                destVC.parentSubject = topic.parentSubjectName
                destVC.quizSourceName = topic.name
            }
        }
        
        if segue.identifier == showSubjectDetailSegueID {
            if let destVC = segue.destination as? SubjectViewController,
               let subjectName = sender as? String {
                destVC.selectedSubject = subjectName
            }
        }
        
        // 🆕 Flashcards Segue
        if segue.identifier == showFlashcardsSegueID {
            /* // Uncomment this once FlashcardsViewController is created
             if let destVC = segue.destination as? FlashcardsViewController,
                let topic = sender as? Topic {
                 destVC.topic = topic
             }
             */
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
                // 🆕 Dynamic height for Side Quests
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
                // Height based on items + spacing
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
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return HomeSection.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = HomeSection.allCases[section]
        switch sectionType {
        case .hero: return heroData.count
        case .sideQuests: return 1
        case .uploadContent: return 1
        case .continueLearning: return 1
        case .quickGames: return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = HomeSection.allCases[indexPath.section]
        
        switch sectionType {
        case .hero:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: hiAlexCellID, for: indexPath) as! HiAlexCollectionViewCell
            cell.delegate = self
            return cell
            
        case .sideQuests:
            // 🆕 Configure Side Quests
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
            if gameItems.count >= 2 {
                cell.configure(with: gameItems[0], and: gameItems[1])
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerID, for: indexPath) as! HeaderViewCollectionReusableView
        let sectionType = HomeSection.allCases[indexPath.section]
        
        // 🆕 Header for Side Quests
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

// MARK: - Side Quests Delegate (XP & History Logic)
extension HomeViewController: SideQuestDelegate {
    func didUpdateQuests(_ quests: [SideQuest]) {
        self.sideQuests = quests
        // Animate resize
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func didCompleteQuest(_ quest: SideQuest) {
        var completed = quest
        completed.isCompleted = true
        self.completedQuests.insert(completed, at: 0) // Add to top of history
    }
    
    func didTapHistory() {
        let vc = QuestHistoryViewController()
        vc.history = self.completedQuests
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            present(vc, animated: true)
        }
    }
    
    func didEarnXP(amount: Int, sourceView: UIView) {
        // Floating XP Animation
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
    }
}

// MARK: - Continue Learning Delegate (Navigation)
extension HomeViewController: ContinueLearningCellDelegate {
    func didSelectLearningItem(_ item: ContentItem) {
        let topic = Topic(
            name: item.title,
            lastAccessed: "Just now",
            materialType: item.itemType, // Pass type dynamically
            largeContentBody: "",
            parentSubjectName: "General"
        )
        
        if item.itemType == "Quiz" {
            performSegue(withIdentifier: showQuizStartSegueID, sender: topic)
        } else if item.itemType == "Flashcard" {
            // 🆕 Flashcard Segue
            performSegue(withIdentifier: showFlashcardsSegueID, sender: topic)
        } else {
            performSegue(withIdentifier: showNotesDetailSegueID, sender: topic)
        }
    }
}

// MARK: - Quick Games Delegate
extension HomeViewController: QuickGamesCellDelegate {
    func didSelectQuickGame(gameTitle: String) {
        let segueID = (gameTitle == "Word Fill") ? showWordFillSegueID : showConnectionsSegueID
        performSegue(withIdentifier: segueID, sender: nil)
    }
}

// MARK: - Upload Delegate
extension HomeViewController: UploadContentCellDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func navigateToConfirmation(with contentName: String) {
        JSONDatabaseManager.shared.addUploadedFile(name: contentName)
        performSegue(withIdentifier: showUploadConfirmationSegueID, sender: contentName)
    }
    
    func uploadCellDidTapDocument(_ cell: UploadContentCollectionViewCell) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .plainText], asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func uploadCellDidTapMedia(_ cell: UploadContentCollectionViewCell) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func uploadCellDidTapLink(_ cell: UploadContentCollectionViewCell) {
        showInputAlert(title: "Add Resource Link", placeholder: "https://...")
    }
    
    func uploadCellDidTapText(_ cell: UploadContentCollectionViewCell) {
        showInputAlert(title: "Quick Note", placeholder: "Enter text content...")
    }
    
    private func showInputAlert(title: String, placeholder: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = placeholder }
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self.navigateToConfirmation(with: text)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        navigateToConfirmation(with: url.lastPathComponent)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            self.navigateToConfirmation(with: "Media Asset")
        }
    }
}

// MARK: - Hi Alex Cell Delegate (Daily Challenge)
extension HomeViewController: HiAlexCellDelegate {
    func didTapPlayNow() {
        performSegue(withIdentifier: showDailyChallengeSegueID, sender: nil)
    }
}
