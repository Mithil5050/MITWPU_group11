//
//  HomeViewController.swift
//  Group_11_Revisio
//
//  Updated for Dropdown Functionality & Profile Icon
//  Updated with AI Floating Button Integration
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
let taskCellID = "TaskCell"

let showStudyPlanSegueID = "ShowStudyPlanSegue"
let showTodayTaskSegueID = "showTodayTaskSegue"
let showConnectionsSegueID = "ConnectionsSegue"
let showWordFillSegueID = "ShowWordFillSegue"
let showUploadConfirmationSegueID = "ShowUploadConfirmation"
let showChatSegueID = "ShowChatSegue" // ✅ NEW: Segue ID for Chat

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
    
    // Dropdown Logic Properties
    var incompleteTasks: [PlanTask] = []
    var isLearningExpanded: Bool = false

    @IBOutlet weak var collectionView: UICollectionView!
    
    // ✅ NEW: Floating AI Button Property
    // ✅ Floating AI Button with Padding for "Exora"
    // ✅ Floating AI Button (Fixed: Manually Resizes Image)
        private let aiFloatingButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.translatesAutoresizingMaskIntoConstraints = false
            
            // 1. Load the original image
            // ⚠️ Make sure your asset is named "exora_icon" (or change this string)
            guard let originalImage = UIImage(named: "exora_icon") else {
                // Fallback if image not found
                btn.setImage(UIImage(systemName: "sparkles"), for: .normal)
                return btn
            }

            // 2. FORCE RESIZE the image to 40x40 points
            // This ensures it fits inside the 60x60 button regardless of original file size
            let targetSize = CGSize(width: 45, height: 45)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let resizedImage = renderer.image { _ in
                originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
            }

            // 3. Configure the Button
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = .label // Black (Light Mode) / White (Dark Mode)
            config.cornerStyle = .capsule
            
            // Set the resized image
            config.image = resizedImage.withRenderingMode(.alwaysOriginal) // .alwaysOriginal keeps original colors!
            
            // 4. Center it perfectly (No padding needed since we resized it)
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            
            btn.configuration = config
            
            // 5. Add Shadow
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
        loadIncompleteTasks()
        setupCollectionView()
        setupProfileIcon()
        
        // ✅ NEW: Initialize Floating Button
        setupFloatingAIButton()
    }
    
    // MARK: - NEW: Floating AI Button Setup
    private func setupFloatingAIButton() {
        // Add to the main view so it floats ABOVE the collection view
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
        // Bounce Animation
        UIView.animate(withDuration: 0.1, animations: {
            self.aiFloatingButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.aiFloatingButton.transform = .identity
            } completion: { _ in
                // Trigger Segue to Chat Interface
                // Ensure you have a Segue in Storyboard with ID: "ShowChatSegue"
                self.performSegue(withIdentifier: showChatSegueID, sender: self)
            }
        }
    }
    
    // MARK: - Profile Icon Setup
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
            GameItem(title: "", imageAsset: "Gemini_Generated_Image_p66f9tp66f9tp66f-removebg-preview"),
            GameItem(title: "", imageAsset: "Gemini_Generated_Image_y6xx8iy6xx8iy6xx-removebg-preview")
        ]
    }

    private func setupCollectionView() {
        registerCustomCells()
        collectionView.collectionViewLayout = generateLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .never
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
        // NOTE: Handle ChatVC preparation here if you need to pass data (like user name)
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
                let rowHeight: CGFloat = 75
                let visibleCount = min(incompleteTasks.count, 3)
                let expandedHeight: CGFloat = isLearningExpanded
                    ? CGFloat(visibleCount + 1) * rowHeight
                    : 75

                let size = NSCollectionLayoutSize(
                    widthDimension: itemWidth,
                    heightDimension: .absolute(expandedHeight)
                )
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                
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

// MARK: - Header Delegate
extension HomeViewController: HeaderViewDelegate {
    func didTapViewAll(in section: Int) {
        isLearningExpanded.toggle()
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
