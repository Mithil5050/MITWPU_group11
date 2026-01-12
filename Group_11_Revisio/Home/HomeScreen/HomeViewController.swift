//
//  HomeViewController.swift
//  Group_11_Revisio
//
//  Updated for Dropdown Functionality
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
let taskCellID = "TaskCell" // Reuse the cell from Study Plan

let showStudyPlanSegueID = "ShowStudyPlanSegue"
let showTodayTaskSegueID = "showTodayTaskSegue"
let showConnectionsSegueID = "ConnectionsSegue"
let showWordFillSegueID = "ShowWordFillSegue"
let showUploadConfirmationSegueID = "ShowUploadConfirmation"

protocol QuickGamesCellDelegate: AnyObject {
    func didSelectQuickGame(gameTitle: String)
}

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - Properties
    var heroData: [ContentItem] = []
    var studyPlanData: [ContentItem] = [ContentItem(title: "Study Plan", iconName: "calendar", itemType: "PlanOverview")]
    var uploadItems: [ContentItem] = []
    var learningItems: [ContentItem] = []
    var gameItems: [GameItem] = []
    
    // 🆕 Dropdown Logic Properties
    var incompleteTasks: [PlanTask] = []
    var isLearningExpanded: Bool = false

    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        loadIncompleteTasks() // 🆕 Load tasks
        setupCollectionView()
    }
    
    // 🆕 Fetch tasks for the dropdown
    private func loadIncompleteTasks() {
        let allSubjects = JSONDatabaseManager.shared.loadStudyPlan()
        incompleteTasks = allSubjects.flatMap { subject in
            subject.days.flatMap { day in
                day.tasks.filter { !$0.isComplete }
            }
        }
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
        collectionView.contentInsetAdjustmentBehavior = .never
    }
    
    @IBAction func profileButtonTapped(_ sender: UIButton) {
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
    }
    
    // MARK: - Layout Configuration
    func generateLayout() -> UICollectionViewLayout {
        let horizontalPadding: CGFloat = 16
        let verticalSpacing: CGFloat = 16

        return UICollectionViewCompositionalLayout { [self] sectionIndex, env in
            let sectionType = HomeSection.allCases[sectionIndex]
            
            // Header Config
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            
            let itemWidth = NSCollectionLayoutDimension.fractionalWidth(1.0)

            switch sectionType {
            case .hero:
                let size = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(124))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                return section
                
            case .uploadContent:
                let size = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(142))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: verticalSpacing, trailing: horizontalPadding)
                return section
                
            case .continueLearning:
                            // Base row height matching LearningTaskCell (80pt)
                            let rowHeight: CGFloat = 75
                            
                            // 1. Calculate items to show
                            let visibleCount = min(incompleteTasks.count, 3)

                            // 2. Dynamic Height Calculation
                            // Collapsed: 70pt (Matches visual card height tightly)
                            // Expanded: Exact height for all rows
                            let expandedHeight: CGFloat = isLearningExpanded
                                ? CGFloat(visibleCount + 1) * rowHeight
                                : 75

                            // 3. Layout Definition
                            let size = NSCollectionLayoutSize(
                                widthDimension: itemWidth,
                                heightDimension: .absolute(expandedHeight)
                            )
                            let item = NSCollectionLayoutItem(layoutSize: size)
                            let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])

                            let section = NSCollectionLayoutSection(group: group)
                            
                            // FIX: Reduced bottom padding from 'verticalSpacing' (20) to 5
                            section.contentInsets = NSDirectionalEdgeInsets(
                                top: 5,
                                leading: horizontalPadding,
                                bottom: 5,
                                trailing: horizontalPadding
                            )
                            
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

            case .studyPlan:
                let size = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .estimated(100))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
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
        // 🆕 Register TaskCell for the dropdown items
        collectionView.register(UINib(nibName: "TaskCell", bundle: nil), forCellWithReuseIdentifier: taskCellID)
        
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
        case .continueLearning:            return 1
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: continueLearningCellID, for: indexPath) as! ContinueLearningCollectionViewCell

            // Pass the tasks and expansion state
            cell.configure(with: self.incompleteTasks)

            return cell
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
            // 🆕 Configure with expansion state
            headerView.configureHeader(with: "Continue Learning", showViewAll: true, section: indexPath.section, isExpanded: isLearningExpanded)
            headerView.delegate = self
        case .quickGames:
            headerView.isHidden = false
            headerView.configureHeader(with: "Quick Games", showViewAll: false, section: indexPath.section)
            headerView.delegate = nil
        default:
            headerView.isHidden = true
        }
        return headerView
    }

    // MARK: - CollectionView Navigation
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionType = HomeSection.allCases[indexPath.section]
        if sectionType == .hero {
            performSegue(withIdentifier: showTodayTaskSegueID, sender: nil)
        } else if sectionType == .studyPlan {
            performSegue(withIdentifier: showStudyPlanSegueID, sender: nil)
        }
    }
}

// MARK: - Header Delegate (The Dropdown Trigger)
extension HomeViewController: HeaderViewDelegate {
    func didTapViewAll(in section: Int) {
        // Toggle state
        isLearningExpanded.toggle()
        
        // Reload just the specific section with animation
        collectionView.performBatchUpdates({
            collectionView.reloadSections(IndexSet(integer: section))
        }, completion: nil)
    }
}

// MARK: - Existing Extensions
extension HomeViewController: QuickGamesCellDelegate {
    func didSelectQuickGame(gameTitle: String) {
        let segueID = (gameTitle == "Word Fill") ? showWordFillSegueID : showConnectionsSegueID
        performSegue(withIdentifier: segueID, sender: nil)
    }
}

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
