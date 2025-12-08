import UIKit

// ⬇️ Removed the redundant HeaderButtonDelegate protocol definition ⬇️

// Place these structures at the very top of HomeViewController.swift
struct ContentItem: Hashable, Sendable {
    let title: String
    let iconName: String
    let itemType: String
}

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
}

// Reuse Identifiers
let hiAlexCellID = "HiAlexCellID"
let uploadContentCellID = "UploadContentCellID"
let continueLearningCellID = "ContinueLearningCellID"
let quickGamesCellID = "QuickGamesCellID"
let headerID = "HeaderID"


// ⬇️ Cleaned Class Signature (removed HeaderButtonDelegate) ⬇️
class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // Segue Constant for the Upload Creation Screen
    let uploadContentSegueID = "ShowUploadCreation"

    // Replace with your actual data source logic (using your custom structs)
    var heroData: [ContentItem] = []
    var uploadItems: [ContentItem] = []
    var learningItems: [ContentItem] = []
    var gameItems: [GameItem] = []

    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Load Dummy Data (Replace with real loading logic)
        heroData = [ContentItem(title: "Hi Alex !", iconName: "", itemType: "Greeting")]
        
        // ⬇️ FIX 1: Added the specific "AddButton" item ⬇️
        uploadItems = [
            ContentItem(title: "Big Data.pdf", iconName: "doc.fill", itemType: "PDF"),
            ContentItem(title: "Data Structures- Trees.com", iconName: "link", itemType: "Link"),
            ContentItem(title: "New File", iconName: "plus.circle.fill", itemType: "AddButton") // Placeholder
        ]
        
        learningItems = [ContentItem(title: "Area under functions", iconName: "", itemType: "Topic")]
        gameItems = [GameItem(title: "Word Scramble", imageAsset: "")]

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
        // ... (body of generateLayout remains the same) ...
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
                let gameItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(150))
                let gameItem = NSCollectionLayoutItem(layoutSize: gameItemSize)
                let gameGroupSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(150))
                let gameGroup = NSCollectionLayoutGroup.horizontal(layoutSize: gameGroupSize, repeatingSubitem: gameItem, count: 2)
                
                let section = NSCollectionLayoutSection(group: gameGroup)
                let gutter: CGFloat = 10
                section.interGroupSpacing = gutter
                gameGroup.interItemSpacing = .fixed(gutter)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                section.boundarySupplementaryItems = [headerItem]
                return section
            }
        }
        return layout
    }
    
    
    func registerCustomCells() {
        // ... (registerCustomCells remains the same) ...
        collectionView.register(UINib(nibName: "HiAlexCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: hiAlexCellID)
        collectionView.register(UINib(nibName: "UploadContentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: uploadContentCellID)
        collectionView.register(UINib(nibName: "ContinueLearningCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: continueLearningCellID)
        collectionView.register(UINib(nibName: "QuickGamesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: quickGamesCellID)
        
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
        case .uploadContent: return 1 // ⬇️ FIX 2: Returns the array count (3) ⬇️
        case .continueLearning: return learningItems.count
        case .quickGames: return gameItems.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = HomeSection.allCases[indexPath.section]
        
        switch sectionType {
        case .hero:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: hiAlexCellID, for: indexPath) as! HiAlexCollectionViewCell
            return cell
            
        case .uploadContent:
            // This cell must now handle individual file items AND the Add button
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: uploadContentCellID, for: indexPath) as! UploadContentCollectionViewCell
            
            _ = uploadItems[indexPath.item]
            
            // NOTE: UploadContentCollectionViewCell needs to be refactored to show ONE file per cell
            // instead of a nested table view. Assuming its configure method now takes a single item:
            // cell.configure(with: item)
            
            // ⬇️ FIX 3: Assign the Closure for the Add Button action ⬇️
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
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader else {
            fatalError("Unexpected supplementary view kind.")
        }
        
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: headerID,
                                                                       for: indexPath) as! HeaderViewCollectionReusableView
        
        let sectionType = HomeSection.allCases[indexPath.section]
        
        let title: String
        switch sectionType {
        case .uploadContent: title = "Upload Content"
        case .continueLearning: title = "Continue Learning"
        case .quickGames: title = "Quick Games"
        default: title = ""
        }
        
        // This is the correct simple call now that the button logic is off the header
        headerView.configureHeader(with: title)
        
        return headerView
    }
}

// MARK: - UICollectionViewDelegate (For Taps)
extension HomeViewController {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionType = HomeSection.allCases[indexPath.section]
        
        switch sectionType {
        case .hero:
            print("Hero Card Tapped: Navigate to Profile/Tasks.")
        case .quickGames:
            print("Game Card Tapped: Start game at index \(indexPath.item)")
            
        case .uploadContent:
            let item = uploadItems[indexPath.item]
            if item.itemType != "AddButton" {
                print("File Tapped: Open file \(item.title)")
            }
            // NOTE: The Add Button navigation is handled by the closure in cellForItemAt, not here.
            
        default:
            break
        }
    }
}
