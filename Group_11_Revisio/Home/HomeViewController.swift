//
//  HomeViewController.swift
//  Group_11_Revisio
//
//  Created by Mithil on 10/12/25.
//

import UIKit
import UniformTypeIdentifiers

// MARK: - Supporting Structures
struct GameItem: Hashable, Sendable {
    let title: String
    let imageAsset: String
}

enum HomeSection: Int, CaseIterable {
    case hero = 0
    case uploadContent
    case continueLearning
    case studyPlan
    case quickGames
}

// MARK: - Constants
let hiAlexCellID = "HiAlexCellID"
let uploadContentCellID = "UploadContentCellID"
let continueLearningCellID = "ContinueLearningCellID"
let quickGamesCellID = "QuickGamesCellID"
let studyPlanCellID = "StudyPlanCellID"
let headerID = "HeaderID"

let showStudyPlanSegueID = "ShowStudyPlanSegue"
let showTodayTaskSegueID = "showTodayTaskSegue"
let showConnectionsSegueID = "ConnectionsSegue"
let showWordFillSegueID = "ShowWordFillSegue"

protocol QuickGamesCellDelegate: AnyObject {
    func didSelectQuickGame(gameTitle: String)
}

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    let uploadContentSegueID = "ShowUploadCreation"

    var heroData: [ContentItem] = []
    var studyPlanData: [ContentItem] = [ContentItem(title: "Study Plan", iconName: "calendar", itemType: "PlanOverview")]
    var uploadItems: [ContentItem] = []
    var learningItems: [ContentItem] = []
    var gameItems: [GameItem] = []

    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupData()
        setupCollectionView()
    }
    
    private func setupData() {
        heroData = [ContentItem(title: "Hi Alex !", iconName: "", itemType: "Greeting")]
        
        uploadItems = [
            ContentItem(title: "Big Data.pdf", iconName: "doc.fill", itemType: "PDF"),
            ContentItem(title: "Data Structures- Trees.com", iconName: "link", itemType: "Link"),
            ContentItem(title: "New File", iconName: "plus.circle.fill", itemType: "AddButton")
        ]
        
        learningItems = [ContentItem(title: "Area under functions", iconName: "", itemType: "Topic")]
        
        gameItems = [
            GameItem(title: "Word Fill", imageAsset: "Screenshot 2025-12-09 at 3.06.21 PM"),
            GameItem(title: "Connections", imageAsset: "Screenshot_2025-12-15_at_3.58.26_PM-removebg-preview-2")
        ]
    }

    private func setupCollectionView() {
        registerCustomCells()
        collectionView.collectionViewLayout = generateLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // CRITICAL: Remove the default safe area padding at the top
        collectionView.contentInsetAdjustmentBehavior = .never
    }
    
    @IBAction func profileButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showProfileSegue", sender: nil)
    }
    
    // MARK: - Layout Configuration
    
    func generateLayout() -> UICollectionViewLayout {
        let horizontalPadding: CGFloat = 20
        let verticalSpacing: CGFloat = 20

        return UICollectionViewCompositionalLayout { sectionIndex, env in
            let sectionType = HomeSection.allCases[sectionIndex]
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            
            let itemWidth = NSCollectionLayoutDimension.fractionalWidth(1.0)

            switch sectionType {
            case .hero:
                // Height adjusted to fit the greeting card properly
                let heroItemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(124))
                let heroItem = NSCollectionLayoutItem(layoutSize: heroItemSize)
                let heroGroup = NSCollectionLayoutGroup.horizontal(layoutSize: heroItemSize, subitems: [heroItem])
                let section = NSCollectionLayoutSection(group: heroGroup)
                
                // TOP INSET: Set to 0 to flush against the top; adjust to ~50 if you want it exactly below the status bar
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                return section
                
            case .uploadContent:
                let listItemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(142))
                let listItemLayout = NSCollectionLayoutItem(layoutSize: listItemSize)
                let listGroup = NSCollectionLayoutGroup.vertical(layoutSize: listItemSize, subitems: [listItemLayout])
                let section = NSCollectionLayoutSection(group: listGroup)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                return section
                
            case .continueLearning:
                let itemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(60))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                section.boundarySupplementaryItems = [headerItem]
                return section
                
            case .quickGames:
                let gameItemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(130))
                let gameItem = NSCollectionLayoutItem(layoutSize: gameItemSize)
                let gameGroup = NSCollectionLayoutGroup.horizontal(layoutSize: gameItemSize, subitems: [gameItem])
                let section = NSCollectionLayoutSection(group: gameGroup)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                section.boundarySupplementaryItems = [headerItem]
                return section

            case .studyPlan:
                let studyPlanItemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(100))
                let studyPlanItem = NSCollectionLayoutItem(layoutSize: studyPlanItemSize)
                let studyPlanGroup = NSCollectionLayoutGroup.horizontal(layoutSize: studyPlanItemSize, subitems: [studyPlanItem])
                let section = NSCollectionLayoutSection(group: studyPlanGroup)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                return section
            }
        }
    }
    
    func registerCustomCells() {
        collectionView.register(UINib(nibName: "HiAlexCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: hiAlexCellID)
        collectionView.register(UINib(nibName: "UploadContentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: uploadContentCellID)
        collectionView.register(UINib(nibName: "ContinueLearningCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: continueLearningCellID)
        collectionView.register(UINib(nibName: "QuickGamesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: quickGamesCellID)
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
        case .uploadContent: return 1
        case .continueLearning: return learningItems.count
        case .quickGames: return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = HomeSection.allCases[indexPath.section]
        
        switch sectionType {
        case .hero:
            return collectionView.dequeueReusableCell(withReuseIdentifier: hiAlexCellID, for: indexPath)
            
        case .studyPlan:
            return collectionView.dequeueReusableCell(withReuseIdentifier: studyPlanCellID, for: indexPath)
            
        case .uploadContent:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: uploadContentCellID, for: indexPath) as! UploadContentCollectionViewCell
            cell.delegate = self
            cell.configure(with: uploadItems)
            return cell
        
        case .continueLearning:
            return collectionView.dequeueReusableCell(withReuseIdentifier: continueLearningCellID, for: indexPath)
            
        case .quickGames:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: quickGamesCellID, for: indexPath) as! QuickGamesCollectionViewCell
            cell.delegate = self
            cell.configure(with: gameItems[0], and: gameItems[1])
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerID, for: indexPath) as! HeaderViewCollectionReusableView
        
        let sectionType = HomeSection.allCases[indexPath.section]
        switch sectionType {
        case .continueLearning:
            headerView.isHidden = false
            headerView.configureHeader(with: "Continue Learning")
        case .quickGames:
            headerView.isHidden = false
            headerView.configureHeader(with: "Quick Games")
        default:
            headerView.isHidden = true
        }
        return headerView
    }

    // MARK: - Navigation
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionType = HomeSection.allCases[indexPath.section]
        switch sectionType {
        case .hero:
            performSegue(withIdentifier: showTodayTaskSegueID, sender: nil)
        case .studyPlan:
            performSegue(withIdentifier: showStudyPlanSegueID, sender: nil)
        default: break
        }
    }
}

// MARK: - QuickGamesCellDelegate Implementation
extension HomeViewController: QuickGamesCellDelegate {
    func didSelectQuickGame(gameTitle: String) {
        let segueID = (gameTitle == "Word Fill") ? showWordFillSegueID : showConnectionsSegueID
        performSegue(withIdentifier: segueID, sender: nil)
    }
}

// MARK: - UploadContentCellDelegate Implementation
//extension HomeViewController: UploadContentCellDelegate {
//    private func presentUploadContent() {
//        // Prefer storyboard instantiation if you have a scene for UploadContentViewController
//        // Otherwise, init directly.
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        if let vc = storyboard.instantiateViewController(withIdentifier: "UploadContentViewController") as? UploadContentViewController {
//            self.navigationController?.pushViewController(vc, animated: true)
//        } else {
//            // Fallback if storyboard ID is not set; instantiate directly.
//            let vc = UploadContentViewController()
//            self.navigationController?.pushViewController(vc, animated: true)
//        }
//    }
extension HomeViewController: UploadContentCellDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func navigateToConfirmation(with contentName: String) {
        // 1. Save the new filename to the JSON "Database"
        JSONDatabaseManager.shared.addUploadedFile(name: contentName)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let confirmationVC = storyboard.instantiateViewController(withIdentifier: "ConfirmationVC") as? UploadConfirmationViewController else {
            print("CRITICAL: Storyboard ID 'ConfirmationVC' not set!")
            return
        }
        
        // 2. Pass the name for the header label
        confirmationVC.uploadedContentName = contentName
        self.navigationController?.pushViewController(confirmationVC, animated: true)
    }
//    func navigateToConfirmation(with contentName: String) {
//            // 1. Access the Main Storyboard
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            
//            // 2. Instantiate the VC using the Storyboard ID "ConfirmationVC"
//            // Ensure you have set this ID in the Identity Inspector in Xcode.
//            guard let confirmationVC = storyboard.instantiateViewController(withIdentifier: "ConfirmationVC")as? UploadConfirmationViewController else {
//                print("Error: Could not find UploadConfirmationViewController with identifier 'ConfirmationVC'")
//                return
//            }
//            
//            // 3. Inject the data into the destination controller
//            confirmationVC.uploadedContentName = contentName
//            
//            // 4. Push onto the navigation stack
//            // This requires the HomeViewController to be embedded in a UINavigationController
//            self.navigationController?.pushViewController(confirmationVC, animated: true)
//        }
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
            } else {
                self.performSegue(withIdentifier: "showUploadConfirmation", sender: nil)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // System Picker Callbacks
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first { navigateToConfirmation(with: url.lastPathComponent) }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { self.navigateToConfirmation(with: "Media Asset") }
    }
}
//    func uploadCellDidTapDocument(_ cell: UploadContentCollectionViewCell) {
//        presentUploadContent()
//    }
//    
//    func uploadCellDidTapMedia(_ cell: UploadContentCollectionViewCell) {
//        presentUploadContent()
//    }
//    
//    func uploadCellDidTapLink(_ cell: UploadContentCollectionViewCell) {
//        presentUploadContent()
//    }
//    
//    func uploadCellDidTapText(_ cell: UploadContentCollectionViewCell) {
//        presentUploadContent()
//    }
//}
