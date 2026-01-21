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
        }

        private func setupCollectionView() {
            allBadgesCollectionView.dataSource = self
            allBadgesCollectionView.delegate = self
            
            if let layout = allBadgesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.minimumInteritemSpacing = horizontalSpacing
                layout.minimumLineSpacing = verticalSpacing
                layout.sectionInset = UIEdgeInsets(top: 0, left: sidePadding, bottom: verticalSpacing, right: sidePadding)
            }
        }
        
        func registerCells() {
            allBadgesCollectionView.register(UINib(nibName: "AllBadgesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "DetailCell")
        }
        
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
        
        // Header
        func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            if kind == UICollectionView.elementKindSectionHeader {
                // This loads the header from Storyboard using the "HeaderView" identifier
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath)
                return header
            }
            return UICollectionReusableView()
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let totalHorizontalSpacing = (sidePadding * 2) + horizontalSpacing
            let width = floor((collectionView.bounds.width - totalHorizontalSpacing) / 2)
            return CGSize(width: width, height: width * cardHeightToWidthRatio)
        }

        // Header height
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
            return CGSize(width: collectionView.frame.width, height: 80)
        }
    }
