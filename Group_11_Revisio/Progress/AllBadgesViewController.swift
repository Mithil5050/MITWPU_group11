//
//  AllBadgesViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 17/01/26.
//
//return badges.isEmpty ? 10 : badges.count
import UIKit

class AllBadgesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var allBadgesCollectionView: UICollectionView!
    
    // Data passed from AwardsViewController
    var badges: [Badge] = BadgeData.monthlyGridBadges
        
        // MARK: - Layout Constants (Matching your Awards Screen)
        private let sidePadding: CGFloat = 20.0
        private let horizontalSpacing: CGFloat = 16.0
        private let verticalSpacing: CGFloat = 20.0
        private let cardHeightToWidthRatio: CGFloat = 1.3

        override func viewDidLoad() {
            super.viewDidLoad()
            setupCollectionView()
            registerCells()
        }

        private func setupCollectionView() {
            allBadgesCollectionView.dataSource = self
            allBadgesCollectionView.delegate = self
            
            // Ensure the Storyboard layout is set to Flow
            if let layout = allBadgesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.minimumInteritemSpacing = horizontalSpacing
                layout.minimumLineSpacing = verticalSpacing
                layout.sectionInset = UIEdgeInsets(top: verticalSpacing, left: sidePadding, bottom: verticalSpacing, right: sidePadding)
            }
        }
        
        func registerCells() {
            // Register your specific grid cell
            allBadgesCollectionView.register(UINib(nibName: "AllBadgesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "DetailCell")
        }

        // MARK: - UICollectionViewDataSource
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return badges.isEmpty ? 6 : badges.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DetailCell", for: indexPath) as? AllBadgesCollectionViewCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: badges[indexPath.row])
            return cell
        }

        // MARK: - UICollectionViewDelegateFlowLayout (The 2-Column Math)
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            // This math forces 2 columns regardless of screen size
            let totalHorizontalSpacing = (sidePadding * 2) + horizontalSpacing
            let width = floor((collectionView.bounds.width - totalHorizontalSpacing) / 2)
            return CGSize(width: width, height: width * cardHeightToWidthRatio)
        }
    }
