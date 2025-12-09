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
            // ... (Your badges array) ...
        Badge(title: "Monthly Challenge", detail: "Upcoming Badge: Pace Setter", isLocked: false, imageAssetName: "awards_monthly_main"),
                // Indices 1 to N: Standard Grid Badges (Total 6 more)
                Badge(title: "Squad MVP", detail: "Earned: 13/09/2025", isLocked: false, imageAssetName: "badge1_squad_mvp_"),
                Badge(title: "Flash Genius", detail: "Earned: 18/09/2025", isLocked: false, imageAssetName: "badge2_flash_genuis"),
                Badge(title: "Monthly Hustler", detail: "Earned: 1/10/2025", isLocked: false, imageAssetName: "badge3_monthly_hustler"),
                Badge(title: "Plan Perfected", detail: "Earned: 17/10/2025", isLocked: false, imageAssetName: "badge4_plan_perfected"),
                Badge(title: "Quiz Master", detail: "Unlock the badge", isLocked: true, imageAssetName: "badge5_quiz_master_lock"),
                Badge(title: "Streak Master", detail: "Unlock the badge", isLocked: true, imageAssetName: "badge6_streak_master_lock"),
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
            
            navigationItem.title = "Awards"
        }
        
        // MARK: - UICollectionViewDataSource (Still inside the class)
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return badges.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
            let badge = badges[indexPath.item]
                
                if indexPath.item == 0 {
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthlyBadgeCell", for: indexPath) as? MonthlyBadgeCollectionViewCell else { fatalError() }
                 //   cell.configure(with: badge) // <-- UNCOMMENTED
                    return cell
                    
                } else {
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell", for: indexPath) as? BadgeCollectionViewCell else { fatalError() }
                    cell.configure(with: badge) // <-- UNCOMMENTED
                    return cell
                }
            
        }
        // The class ends here, before the extensions start
    }

    // MARK: - 3. UICollectionViewDelegateFlowLayout (Sizing Logic)

    extension AwardsViewController: UICollectionViewDelegateFlowLayout {
        // ... (Your sizeForItemAt function goes here, exactly as you provided) ...
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
                
                guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
                
                // --- Retrieve Layout Values from viewDidLoad ---
                let sectionInsets = flowLayout.sectionInset
                let interItemSpacing = flowLayout.minimumInteritemSpacing
                
                let totalHorizontalPadding = sectionInsets.left + sectionInsets.right
                
                // --- Sizing Logic ---
                
                if indexPath.item == 0 {
                    // A. Feature Cell (Index 0): Full Width (130 points tall)
                    let width = collectionView.bounds.width - sectionInsets.left - sectionInsets.right
                    let height: CGFloat = 130.0
                    return CGSize(width: width, height: height)
                    
                } else {
                    // B. Standard Cells (Index 1+): Two Columns
                    let numberOfColumns: CGFloat = 2
                    let totalSpacing = interItemSpacing * (numberOfColumns - 1)
                    
                    let availableWidth = collectionView.bounds.width - totalHorizontalPadding - totalSpacing
                    
                    let cellWidth = floor(availableWidth / numberOfColumns)
                    let cellHeight = cellWidth * 1.3 // Taller rectangle shape
                    
                    return CGSize(width: cellWidth, height: cellHeight)
                }
            }
        }
    
