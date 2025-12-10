import UIKit

// Place these structures at the very top of HomeViewController.swift
//struct ContentItem: Hashable, Sendable {
//    let title: String
//    let iconName: String
//    let itemType: String
//}

struct GameItem: Hashable, Sendable {
    let title: String
    let imageAsset: String
}

// Define your Home Screen Sections
enum HomeSection: Int, CaseIterable {
    case hero = 0
    case uploadContent
    case continueLearning
    case quickGames
    // Study Plan section moved to the end
    case studyPlan
}

// Reuse Identifiers
let hiAlexCellID = "HiAlexCellID"
let uploadContentCellID = "UploadContentCellID"
let continueLearningCellID = "ContinueLearningCellID"
let quickGamesCellID = "QuickGamesCellID"
let studyPlanCellID = "StudyPlanCellID"
let headerID = "HeaderID"


class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // Segue Constant for the Upload Creation Screen
    let uploadContentSegueID = "ShowUploadCreation"

    // Replace with your actual data source logic (using your custom structs)
    var heroData: [ContentItem] = []
    // Placeholder data for the single Study Plan item
    var studyPlanData: [ContentItem] = [ContentItem(title: "Study Plan", iconName: "calendar", itemType: "PlanOverview")]
    var uploadItems: [ContentItem] = []
    var learningItems: [ContentItem] = []
    var gameItems: [GameItem] = []

    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Load Dummy Data (Replace with real loading logic)
        heroData = [ContentItem(title: "Hi Alex !", iconName: "", itemType: "Greeting")]
        
        // Added the specific "AddButton" item
        uploadItems = [
            ContentItem(title: "Big Data.pdf", iconName: "doc.fill", itemType: "PDF"),
            ContentItem(title: "Data Structures- Trees.com", iconName: "link", itemType: "Link"),
            ContentItem(title: "New File", iconName: "plus.circle.fill", itemType: "AddButton") // Placeholder
        ]
        
        learningItems = [ContentItem(title: "Area under functions", iconName: "", itemType: "Topic")]
        
        // Game data updated for two distinct quick games
        gameItems = [
            GameItem(title: "Word Fill", imageAsset: "Screenshot 2025-12-09 at 3.06.21 PM"),
            GameItem(title: "Connections", imageAsset: "Screenshot 2025-12-09 at 12.28.48 PM.png")
        ]

        // 2. Setup
        registerCustomCells()
        collectionView.collectionViewLayout = generateLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    // Action connected to the Profile button in the Navigation Bar (assuming a Segue named "showProfileSegue")
    @IBAction func profileButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showProfileSegue", sender: nil)
    }
    
    // MARK: - Layout Configuration
    
    func generateLayout() -> UICollectionViewLayout {
        let horizontalPadding: CGFloat = 20
        let verticalSpacing: CGFloat = 20

        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
                
            let sectionType = HomeSection.allCases[sectionIndex]
                
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            
            let itemWidth = NSCollectionLayoutDimension.fractionalWidth(1.0)
            let itemHeight = NSCollectionLayoutDimension.estimated(60)

            switch sectionType {
            case .hero:
                let heroItemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(180))
                let heroItem = NSCollectionLayoutItem(layoutSize: heroItemSize)
                let heroGroup = NSCollectionLayoutGroup.horizontal(layoutSize: heroItemSize, subitems: [heroItem])
                let section = NSCollectionLayoutSection(group: heroGroup)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                return section
                
            case .uploadContent:
                // Header is intentionally removed here
                let listItemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(130))
                let listItemLayout = NSCollectionLayoutItem(layoutSize: listItemSize)
                let listGroupSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(1))
                let listGroup = NSCollectionLayoutGroup.vertical(layoutSize: listGroupSize, subitems: [listItemLayout])
                
                let section = NSCollectionLayoutSection(group: listGroup)
                section.interGroupSpacing = 1
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                // No boundarySupplementaryItems for UploadContent
                return section
                
            case .continueLearning:
                let listItemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: itemHeight)
                let listItemLayout = NSCollectionLayoutItem(layoutSize: listItemSize)
                let listGroupSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(1))
                let listGroup = NSCollectionLayoutGroup.vertical(layoutSize: listGroupSize, subitems: [listItemLayout])
                
                let section = NSCollectionLayoutSection(group: listGroup)
                section.interGroupSpacing = 1
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                section.boundarySupplementaryItems = [headerItem]
                return section
                
            case .quickGames:
                // The size is set to full width to accommodate the single cell containing two views.
                let gameItemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(130))
                let gameItem = NSCollectionLayoutItem(layoutSize: gameItemSize)
                let gameGroup = NSCollectionLayoutGroup.horizontal(layoutSize: gameItemSize, subitems: [gameItem])
                
                let section = NSCollectionLayoutSection(group: gameGroup)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                section.boundarySupplementaryItems = [headerItem]
                return section

            // Study Plan Layout (at the end)
            case .studyPlan:
                let studyPlanItemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(100))
                let studyPlanItem = NSCollectionLayoutItem(layoutSize: studyPlanItemSize)
                let studyPlanGroup = NSCollectionLayoutGroup.horizontal(layoutSize: studyPlanItemSize, subitems: [studyPlanItem])
                let section = NSCollectionLayoutSection(group: studyPlanGroup)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                return section
            }
        }
        return layout
    }
    
    
    func registerCustomCells() {
        collectionView.register(UINib(nibName: "HiAlexCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: hiAlexCellID)
        collectionView.register(UINib(nibName: "UploadContentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: uploadContentCellID)
        collectionView.register(UINib(nibName: "ContinueLearningCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: continueLearningCellID)
        collectionView.register(UINib(nibName: "QuickGamesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: quickGamesCellID)
        // Registration for the new cells
        collectionView.register(UINib(nibName: "StudyPlanCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: studyPlanCellID)
        collectionView.register(UINib(nibName: "HeaderViewCollectionReusableView", bundle: nil),
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: headerID)
    }
    
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return HomeSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = HomeSection.allCases[section]
        switch sectionType {
        case .hero: return heroData.count
        case .studyPlan: return studyPlanData.count
        case .uploadContent: return 1 // Single cell containing the table view
        case .continueLearning: return learningItems.count
        case .quickGames: return 1 // 💡 FIX: Returns 1 cell to hold both game cards
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = HomeSection.allCases[indexPath.section]
        
        switch sectionType {
        case .hero:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: hiAlexCellID, for: indexPath) as! HiAlexCollectionViewCell
            return cell
            
        case .studyPlan:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: studyPlanCellID, for: indexPath) as! StudyPlanCollectionViewCell
            return cell
            
        case .uploadContent:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: uploadContentCellID, for: indexPath) as! UploadContentCollectionViewCell
            
            // Configure the inner table view with the file list
            cell.configure(with: uploadItems)
            
            // Assign the Closure for the Add Button action
            cell.onAddTapped = { [weak self] in
                guard let self = self else { return }
                
                print("Upload Content Button Tapped via Cell Closure.")
                self.performSegue(withIdentifier: self.uploadContentSegueID, sender: nil)
            }
            
            return cell
            
        case .continueLearning:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: continueLearningCellID, for: indexPath) as! ContinueLearningCollectionViewCell
            return cell
            
        case .quickGames:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: quickGamesCellID, for: indexPath) as! QuickGamesCollectionViewCell
            
            let item1 = gameItems[0] // Word Scramble
            let item2 = gameItems[1] // Connections
            
            // 💡 FIX: Configure the single cell with BOTH data items
            // This relies on QuickGamesCollectionViewCell having the configure(with:and:) method.
            cell.configure(with: item1, and: item2)
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader else {
            fatalError("Unexpected supplementary view kind.")
        }
        
        let sectionType = HomeSection.allCases[indexPath.section]
        
        // Check if the section actually uses the supplementary header view.
        switch sectionType {
        case .hero, .studyPlan, .uploadContent:
            // These sections do not use an external header.
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: headerID,
                                                                   for: indexPath)
            
        case .continueLearning, .quickGames:
            // These sections require and use the configured HeaderViewCollectionReusableView.
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                           withReuseIdentifier: headerID,
                                                                           for: indexPath) as! HeaderViewCollectionReusableView
            
            let title: String
            switch sectionType {
            case .continueLearning: title = "Continue Learning"
            case .quickGames: title = "Quick Games"
            default: title = "" // Should not be reached
            }
            
            headerView.configureHeader(with: title)
            return headerView
        }
    }
}

// MARK: - UICollectionViewDelegate (For Taps)
extension HomeViewController {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionType = HomeSection.allCases[indexPath.section]
        
        switch sectionType {
        case .hero:
            print("Hero Card Tapped: Navigate to Profile/Tasks.")
        
        case .studyPlan:
            print("Study Plan Card Tapped: Navigate to the full Study Plan interface.")
            
        case .quickGames:
            // Note: This tap will register for the entire container cell. You may need
            // to implement hit testing within QuickGamesCollectionViewCell to know which
            // card was tapped.
            print("Quick Games Container Tapped.")
            
        case .uploadContent:
            // Taps on the file list inside the cell are handled by the inner UITableViewDelegate.
            break
            
        case .continueLearning:
            print("Continue Learning Tapped: Open item at index \(indexPath.item)")
            
        }
    }
}
