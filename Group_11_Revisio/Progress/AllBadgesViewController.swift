//
//  AllBadgesViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 17/01/26.

import UIKit

class AllBadgesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var allBadgesCollectionView: UICollectionView!
    
    var badges: [Badge] = BadgeData.earnedBadges
        
        private let sidePadding: CGFloat = 20.0
        private let horizontalSpacing: CGFloat = 16.0
        private let verticalSpacing: CGFloat = 20.0
        private let cardHeightToWidthRatio: CGFloat = 1.0
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupCollectionView()
            registerCells()
            
            // Sets the title in the Navigation Bar
            navigationItem.title = "All Awards"
        }

        private func setupCollectionView() {
            allBadgesCollectionView.dataSource = self
            allBadgesCollectionView.delegate = self
            
            // Force the view to be scrollable even with little content
            allBadgesCollectionView.alwaysBounceVertical = true
            allBadgesCollectionView.isScrollEnabled = true
            
            if let layout = allBadgesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.minimumInteritemSpacing = horizontalSpacing
                layout.minimumLineSpacing = verticalSpacing
                // Added bottom inset (60) to prevent the tab bar from blocking content
                layout.sectionInset = UIEdgeInsets(top: 0, left: sidePadding, bottom: 60, right: sidePadding)
            }
        }
        
        func registerCells() {
            // Registers your custom XIB cell
            allBadgesCollectionView.register(UINib(nibName: "AllBadgesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "DetailCell")
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return badges.isEmpty ? 6 : badges.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DetailCell", for: indexPath) as? AllBadgesCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            // Safety check for array bounds
            if !badges.isEmpty {
                cell.configure(with: badges[indexPath.row])
            }
            return cell
        }
        
        // MARK: - Header Logic
        func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            if kind == UICollectionView.elementKindSectionHeader {
                // This loads the header you designed in the Storyboard with identifier "HeaderView"
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath)
                return header
            }
            return UICollectionReusableView()
        }
        
        // MARK: - Layout Delegate
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            // Calculates 2-column width based on screen width and padding
            let totalHorizontalSpacing = (sidePadding * 2) + horizontalSpacing
            let width = floor((collectionView.bounds.width - totalHorizontalSpacing) / 2)
            return CGSize(width: width, height: width * cardHeightToWidthRatio)
        }

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
            return CGSize(width: collectionView.frame.width, height: 80)
        }
    }
