//
//  AwardsViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 08/12/25.
//

import UIKit

struct Badge {
    let title: String
    let detail: String
    let isLocked: Bool
    let imageAssetName: String
}

class AwardsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Placeholder data array (replace with your actual ViewModel/data source)
        var badges: [Badge] = [
                Badge(title: "Monthly Challenge", detail: "Upcoming Badge: Pace Setter", isLocked: false, imageAssetName: "monthly_challenge"),
                Badge(title: "Squad MVP", detail: "Earned: 13/09/2025", isLocked: false, imageAssetName: "squad_mvp"),
                Badge(title: "Flash Genius", detail: "Earned: 18/09/2025", isLocked: false, imageAssetName: "flash_genius"),
                Badge(title: "Monthly Hustler", detail: "Earned: 1/10/2025", isLocked: false, imageAssetName: "monthly_hustler"),
                Badge(title: "Plan Perfected", detail: "Earned: 17/10/2025", isLocked: false, imageAssetName: "plan_perfected"),
                Badge(title: "Quiz Master", detail: "Unlock the badge", isLocked: true, imageAssetName: "quiz_master_lock"),
                Badge(title: "Streak Master", detail: "Unlock the badge", isLocked: true, imageAssetName: "streak_master_lock"),
            ]
            
    override func viewDidLoad() {
                super.viewDidLoad()
                
                // --- Essential Setup ---
                collectionView.dataSource = self
                collectionView.delegate = self
                
                if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    layout.minimumInteritemSpacing = 16
                    layout.minimumLineSpacing = 20
                    layout.sectionInset = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
                }
                
                navigationItem.title = "Achievements"
            }
        }

        // MARK: - 2. UICollectionViewDataSource & Delegate (OUTSIDE the class)

        extension AwardsViewController {
            
            // UICollectionViewDataSource: Number of items
            func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                return badges.count
            }

            // UICollectionViewDataSource: Cell for item
            func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                
                let badge = badges[indexPath.item]
                
                if indexPath.item == 0 {
                    // Feature Cell (Using the provided name change)
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthlyBadgeCell", for: indexPath) as? MonthlyBadgeCollectionViewCell else {
                        // If you used "FeatureCell" and "FeatureBadgeCollectionViewCell" before, change the names here too.
                        fatalError("Failed to dequeue MonthlyBadgeCell")
                    }
                    // cell.configure(with: badge)
                    return cell
                    
                } else {
                    // Standard Cell
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell", for: indexPath) as? BadgeCollectionViewCell else {
                        fatalError("Failed to dequeue BadgeCell")
                    }
                    // cell.configure(with: badge)
                    return cell
                }
            }
            
            // UICollectionViewDelegate: Did Select Item (Optional, for handling taps)
            func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
                // Handle cell selection/tap here
            }
        }

        // MARK: - 3. UICollectionViewDelegateFlowLayout (Sizing Logic)

        // NOTE: This extension MUST be separate to handle the sizing protocol.
        extension AwardsViewController: UICollectionViewDelegateFlowLayout {
            
            func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
                
                guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
                
                // --- Retrieve Layout Values from viewDidLoad ---
                let sectionInsets = flowLayout.sectionInset
                let interItemSpacing = flowLayout.minimumInteritemSpacing
                
                let totalHorizontalPadding = sectionInsets.left + sectionInsets.right
                
                // --- Sizing Logic ---
                
                if indexPath.item == 0 {
                    // Feature Cell (Full Width)
                    // Width is total bounds width minus section insets (20 left + 20 right)
                    let width = collectionView.bounds.width - sectionInsets.left - sectionInsets.right
                    let height: CGFloat = 130.0
                    return CGSize(width: width, height: height)
                    
                } else {
                    // Standard Cells (Two Columns)
                    let numberOfColumns: CGFloat = 2
                    let totalSpacing = interItemSpacing * (numberOfColumns - 1)
                    
                    let availableWidth = collectionView.bounds.width - totalHorizontalPadding - totalSpacing
                    
                    let cellWidth = floor(availableWidth / numberOfColumns)
                    let cellHeight = cellWidth * 1.3
                    
                    return CGSize(width: cellWidth, height: cellHeight)
                }
            }
        }
