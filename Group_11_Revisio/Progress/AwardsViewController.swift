//
//  AwardsViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import UIKit

// NOTE: The Badge struct must be available (e.g., defined in DataModels.swift)

class AwardsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MonthlyBadgeCellDelegate {
    
    // MARK: - Outlets (Similar to your example's single CollectionView outlet)
    @IBOutlet weak var featuredCollectionView: UICollectionView!
    @IBOutlet weak var gridCollectionView: UICollectionView!
    
    // MARK: - Data
        var badges: [Badge] = BadgeData.allBadges
        
        // MARK: - Constants
        private let sidePadding: CGFloat = 20.0
        private let horizontalSpacing: CGFloat = 16.0
        private let verticalSpacing: CGFloat = 20.0
        private let numberOfColumns: CGFloat = 2.0
        private let cardHeightToWidthRatio: CGFloat = 1.3
        private let featuredCardHeight: CGFloat = 130.0
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupCollectionViews()
            registerCells()
            setupLayouts()
            navigationItem.title = "Awards"
        }
        
        private func setupCollectionViews() {
            featuredCollectionView.dataSource = self
            featuredCollectionView.delegate = self
            gridCollectionView.dataSource = self
            gridCollectionView.delegate = self
        }
        
        func registerCells() {
            featuredCollectionView.register(UINib(nibName: "MonthlyBadgeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "MonthlyFeatureCell")
            gridCollectionView.register(UINib(nibName: "BadgeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BadgeGridCell")
        }

        func setupLayouts() {
            if let gridLayout = gridCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                gridLayout.minimumInteritemSpacing = horizontalSpacing
                gridLayout.minimumLineSpacing = verticalSpacing
                gridLayout.sectionInset = UIEdgeInsets(top: verticalSpacing, left: sidePadding, bottom: verticalSpacing, right: sidePadding)
            }
            if let featuredLayout = featuredCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                featuredLayout.sectionInset = UIEdgeInsets(top: 0, left: sidePadding, bottom: 0, right: sidePadding)
            }
        }

        // MARK: - UICollectionViewDataSource
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return collectionView == featuredCollectionView ? 1 : badges.count - 1
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            if collectionView == featuredCollectionView {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthlyFeatureCell", for: indexPath) as? MonthlyBadgeCollectionViewCell else { fatalError() }
                cell.delegate = self // Connect the bridge
                cell.configure(with: badges[0])
                return cell
            } else {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeGridCell", for: indexPath) as? BadgeCollectionViewCell else { fatalError() }
                cell.configure(with: badges[indexPath.item + 1])
                return cell
            }
        }

        // MARK: - Navigation / Segue Logic
        func didTapMonthlyBadgeCard() {
                // We initialize the specific detail controller using its XIB name
                let detailVC = MonthlyChallengeDetailViewController(nibName: "MonthlyChallengeDetailViewController", bundle: nil)
                
                // Push it onto the navigation stack
                self.navigationController?.pushViewController(detailVC, animated: true)
            }

        func didTapShowAllButton() {
            self.performSegue(withIdentifier: "ShowAllBadges", sender: self)
        }
    }

    // MARK: - Layout Extension
    extension AwardsViewController: UICollectionViewDelegateFlowLayout {
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            if collectionView == featuredCollectionView {
                return CGSize(width: collectionView.bounds.width - (sidePadding * 2), height: featuredCardHeight)
            } else {
                let totalSpacing = (sidePadding * 2) + horizontalSpacing
                let width = floor((collectionView.bounds.width - totalSpacing) / 2)
                return CGSize(width: width, height: width * cardHeightToWidthRatio)
            }
        }
    }
