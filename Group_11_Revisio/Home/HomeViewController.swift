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
        
        // FIX 1: Added the specific "AddButton" item
        uploadItems = [
            ContentItem(title: "Big Data.pdf", iconName: "doc.fill", itemType: "PDF"),
            ContentItem(title: "Data Structures- Trees.com", iconName: "link", itemType: "Link"),
            ContentItem(title: "New File", iconName: "plus.circle.fill", itemType: "AddButton") // Placeholder
        ]
        
        learningItems = [ContentItem(title: "Area under functions", iconName: "", itemType: "Topic")]
        
        // Update gameItems to have two distinct entries
        gameItems = [
            GameItem(title: "Word Scramble", imageAsset: "Screenshot 2025-12-09 at 3.06.21 PM"),
            // NOTE: "calendar" is an SF Symbol, assuming it's available.
            GameItem(title: "Quick Quiz", imageAsset: "calendar")
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
                
            case .uploadContent, .continueLearning:
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
                // Height updated to match the .xib file's size estimation for games
                let gameItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(130))
                let gameItem = NSCollectionLayoutItem(layoutSize: gameItemSize)
                let gameGroupSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(130))
                let gameGroup = NSCollectionLayoutGroup.horizontal(layoutSize: gameGroupSize, repeatingSubitem: gameItem, count: 2)
                
                let section = NSCollectionLayoutSection(group: gameGroup)
                let gutter: CGFloat = 10
                section.interGroupSpacing = gutter
                gameGroup.interItemSpacing = .fixed(gutter)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                section.boundarySupplementaryItems = [headerItem]
                return section

            // Study Plan Layout (now at the end)
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
        // Registration for the new cell
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
        case .uploadContent: return 1 // Assuming this count is correct for one container cell
        case .continueLearning: return learningItems.count
        case .quickGames: return gameItems.count // Returns 2 items
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
            
            _ = uploadItems[indexPath.item]
            
            // Assign the Closure for the Add Button action
            // NOTE: The cell must have the onAddTapped closure defined.
            // cell.onAddTapped = { [weak self] in ... }
            
            return cell
            
        case .continueLearning:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: continueLearningCellID, for: indexPath) as! ContinueLearningCollectionViewCell
            return cell
            
        case .quickGames:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: quickGamesCellID, for: indexPath) as! QuickGamesCollectionViewCell
            
            _ = gameItems[indexPath.item]
            
            // NOTE: The QuickGamesCollectionViewCell must have the configure method implemented.
            // cell.configure(with: gameItem)
            
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
        case .hero, .studyPlan:
            // For sections without an external header, safely dequeue a generic view.
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: headerID,
                                                                   for: indexPath)
            
        case .uploadContent, .continueLearning, .quickGames:
            // These sections require and use the configured HeaderViewCollectionReusableView.
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                           withReuseIdentifier: headerID,
                                                                           for: indexPath) as! HeaderViewCollectionReusableView
            
            let title: String
            switch sectionType {
            case .uploadContent: title = "Upload Content"
            case .continueLearning: title = "Continue Learning"
            case .quickGames: title = "Quick Games"
            default: fatalError("Section requiring a header title was not handled.")
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
            print("Game Card Tapped: Start game at index \(indexPath.item)")
            
        case .uploadContent:
            let item = uploadItems[indexPath.item]
            if item.itemType != "AddButton" {
                print("File Tapped: Open file \(item.title)")
            }
            
        case .continueLearning:
            print("Continue Learning Tapped: Open item at index \(indexPath.item)")
            
        }
    }
}
