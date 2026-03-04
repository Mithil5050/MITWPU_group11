//
//  AwardsViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import UIKit

// 1. Define the 4 Sections
enum AwardsSection: Int, CaseIterable {
    case feature = 0          // Large Monthly Badge
    case activeChallenges = 1 // Horizontal Scroll (closest to completion)
    case recentWins = 2       // Horizontal Scroll (recently earned)
    case allMilestones = 3    // Vertical Grid (all categories)
}

class AwardsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
        
    var milestones: [Badging.Badge] = []

        override func viewDidLoad() {
            super.viewDidLoad()
            setupData()
            setupCollectionView()
            navigationItem.title = "Awards"
            
            NotificationCenter.default.addObserver(self, selector: #selector(refreshAwardsData), name: .xpDidUpdate, object: nil)
        }
        
        @objc private func refreshAwardsData() {
            DispatchQueue.main.async { self.collectionView.reloadData() }
        }

        private func setupData() {
            self.milestones = BadgeData.allMilestones
        }

        private func setupCollectionView() {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.collectionViewLayout = createLayout()
            
            collectionView.register(UINib(nibName: "MonthlyBadgeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "MonthlyFeatureCell")
            collectionView.register(UINib(nibName: "BadgeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BadgeCell")
            collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
            
            collectionView.backgroundColor = .black
        }

        private func createLayout() -> UICollectionViewLayout {
            return UICollectionViewCompositionalLayout { (sectionIndex, env) -> NSCollectionLayoutSection? in
                guard let sectionType = AwardsSection(rawValue: sectionIndex) else { return nil }
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(35))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

                switch sectionType {
                case .feature:
                    let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(110)), subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
                    return section

                case .allMilestones:
                    let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(150)))
                    item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(150)), subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 20, trailing: 8)
                    section.boundarySupplementaryItems = [header]
                    return section

                default: // activeChallenges and recentWins
                    let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
                    // ✅ absolute(85) height ensures the centered multi-line text is visible
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(85))
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                    section.boundarySupplementaryItems = [header]
                    return section
                }
            }
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            let type = AwardsSection(rawValue: section)!
            if type == .allMilestones { return 4 } // ✅ Fixed 4 grids as requested
            return 1
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let section = AwardsSection(rawValue: indexPath.section)!
            let hasActivity = ProgressDataManager.shared.hasEarnedAnyXP
            
            if section == .feature {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthlyFeatureCell", for: indexPath) as! MonthlyBadgeCollectionViewCell
                cell.configure(with: milestones[0])
                return cell
            }
            else if section == .activeChallenges || section == .recentWins {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell", for: indexPath) as! BadgeCollectionViewCell
                if !hasActivity {
                    cell.showEmptyState(section: section) // ✅ Use the updated centered state
                } else {
                    cell.badgeCardView.isHidden = false
                    cell.configure(with: milestones[indexPath.row], forSection: section)
                }
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell", for: indexPath) as! BadgeCollectionViewCell
                cell.badgeCardView.isHidden = false
                cell.configure(with: milestones[indexPath.row], forSection: section)
                return cell
            }
        }

        func numberOfSections(in collectionView: UICollectionView) -> Int { return AwardsSection.allCases.count }

        func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as! SectionHeaderView
            let titles = ["", "Focus Challenges", "Recent Achievements", "All Milestones"]
            header.titleLabel.text = titles[indexPath.section]
            header.showAllButton.isHidden = true // ✅ REMOVE SHOW ALL BUTTON
            return header
        }
    }
