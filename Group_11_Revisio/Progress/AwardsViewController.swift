//
//  AwardsViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import UIKit

// NOTE: The Badge struct must be available (e.g., defined in DataModels.swift)

class AwardsViewController: UIViewController {
    
    // MARK: - Outlets (Similar to your example's single CollectionView outlet)
    @IBOutlet weak var featuredCollectionView: UICollectionView!
    @IBOutlet weak var gridCollectionView: UICollectionView!
    
    // MARK: - Data and Constants
    private let sidePadding: CGFloat = 20.0
    private let horizontalSpacing: CGFloat = 16.0
    private let verticalSpacing: CGFloat = 20.0
    private let numberOfColumns: CGFloat = 2.0
    private let cardHeightToWidthRatio: CGFloat = 1.3
    private let featuredCardHeight: CGFloat = 130.0
    
    var badges: [Badge] = [
        // Index 0: FEATURED BADGE (Displayed in featuredCollectionView)
        Badge(title: "Monthly Challenge", detail: "Upcoming Badge: Pace Setter", isLocked: false, imageAssetName: "awards_monthly_main"),
        
        // Indices 1 to N: GRID BADGES (Displayed in gridCollectionView)
        Badge(title: "Squad MVP", detail: "Earned: 13/09/2025", isLocked: false, imageAssetName: "badge1_squad_mvp"),
        Badge(title: "Flash Genius", detail: "Earned: 18/09/2025", isLocked: false, imageAssetName: "badge2_flash_genuis"),
        Badge(title: "Monthly Hustler", detail: "Earned: 1/10/2025", isLocked: false, imageAssetName: "badge3_monthly_hustler"),
        Badge(title: "Plan Perfected", detail: "Earned: 17/10/2025", isLocked: false, imageAssetName: "badge4_plan_perfected"),
        Badge(title: "Quiz Master", detail: "Unlock the badge", isLocked: true, imageAssetName: "badge5_quiz_master_lock"),
        Badge(title: "Streak Master", detail: "Unlock the badge", isLocked: true, imageAssetName: "badge6_streak_master_lock"),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Setup Delegates and Data Sources (Similar to your example)
        featuredCollectionView.dataSource = self
        featuredCollectionView.delegate = self
        gridCollectionView.dataSource = self
        gridCollectionView.delegate = self
        
        // 2. Register Cells (Similar to your example's registerCell function)
        registerCells()
        
        // 3. Set Layouts (Using FlowLayout setup instead of CompositionalLayout)
        // Note: For two collection views, it's easier to set FlowLayout properties directly
        // in viewDidLoad rather than using a complex generateLayout function unless needed.
        setupLayouts()
        
        navigationItem.title = "Achievements"
    }
    
    // MARK: - Setup Functions (Similar to your registerCell function)
    
    func registerCells() {
        // Register the full-width Monthly Badge Cell (to the featured view)
        featuredCollectionView.register(UINib(nibName: "MonthlyBadgeCollectionViewCell", bundle: nil),
                                        forCellWithReuseIdentifier: "MonthlyFeatureCell")
        
        // Register the standard Grid Badge Cell (to the grid view)
        gridCollectionView.register(UINib(nibName: "BadgeCollectionViewCell", bundle: nil),
                                    forCellWithReuseIdentifier: "BadgeGridCell")
        
        // NOTE: No header registration is needed here unless you are adding a header to the gridCollectionView.
    }
    
    func setupLayouts() {
        // --- Grid View Layout Setup ---
        if let gridLayout = gridCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            gridLayout.minimumInteritemSpacing = horizontalSpacing
            gridLayout.minimumLineSpacing = verticalSpacing
            gridLayout.sectionInset = UIEdgeInsets(top: verticalSpacing,
                                                   left: sidePadding,
                                                   bottom: verticalSpacing,
                                                   right: sidePadding)
        }
        
        // --- Featured View Layout Setup ---
        if let featuredLayout = featuredCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            featuredLayout.sectionInset = UIEdgeInsets(top: 0, left: sidePadding, bottom: 0, right: sidePadding)
            featuredLayout.minimumLineSpacing = 0
            featuredLayout.minimumInteritemSpacing = 0
        }
    }
}

// MARK: - UICollectionViewDataSource (Differentiating Logic - Similar to your example)

extension AwardsViewController: UICollectionViewDataSource {
    
    // The number of sections is 1 for both collection views, as they are separate views.
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == featuredCollectionView {
            // Featured view always shows 1 item
            return 1
        } else {
            // Grid view shows the rest of the items (badges.count - 1)
            return badges.count - 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == featuredCollectionView {
            // Dequeue the full-width feature cell
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthlyFeatureCell", for: indexPath) as? MonthlyBadgeCollectionViewCell else { fatalError("Could not dequeue MonthlyFeatureCell") }
            cell.configure(with: badges[0])
            return cell
            
        } else {
            // Dequeue the standard grid cell
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeGridCell", for: indexPath) as? BadgeCollectionViewCell else { fatalError("Could not dequeue BadgeGridCell") }
            
            // Adjust index to skip the first (featured) badge
            let badge = badges[indexPath.item + 1]
            cell.configure(with: badge)
            return cell
        }
    }
    
    // NOTE: You do NOT implement viewForSupplementaryElementOfKind here, as you
    // don't seem to be using reusable headers or footers in the current design.
}

// MARK: - UICollectionViewDelegateFlowLayout (Differentiating Sizing)

extension AwardsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // Calculate total horizontal space used by padding and spacing
        let totalPaddingAndSpacing = (sidePadding * 2) + (horizontalSpacing * (numberOfColumns - 1))
        
        if collectionView == featuredCollectionView {
            // A. Feature Cell: Full Width, fixed height
            let width = collectionView.bounds.width - (sidePadding * 2)
            return CGSize(width: width, height: featuredCardHeight)
            
        } else {
            // B. Standard Cells (Grid View): Two Columns
            let availableWidth = collectionView.bounds.width - totalPaddingAndSpacing
            let cellWidth = floor(availableWidth / numberOfColumns)
            let cellHeight = cellWidth * cardHeightToWidthRatio
            
            return CGSize(width: cellWidth, height: cellHeight)
        }
    }
    
    // Ensure spacing and inset methods are implemented to override any Storyboard defaults
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == gridCollectionView {
            return UIEdgeInsets(top: verticalSpacing, left: sidePadding, bottom: verticalSpacing, right: sidePadding)
        }
        return UIEdgeInsets(top: 0, left: sidePadding, bottom: 0, right: sidePadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionView == gridCollectionView ? horizontalSpacing : 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return collectionView == gridCollectionView ? verticalSpacing : 0
    }
}
