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

            // ✅ HIERARCHICAL LOGIC: Only show the "next in line" badge for each category
            var activeBadges: [Badging.Badge] {
                var nextBadgesInLine: [Badging.Badge] = []
                
                // 1. Loop through every badge category (Quiz Master, Focus, etc.)
                for category in Badging.BadgeCategory.allCases {
                    // Get all badges belonging to this specific category
                    let badgesInCategory = milestones.filter { $0.category == category }
                    
                    // Sort them from Bronze (1) to Gold (3)
                    let sortedBadges = badgesInCategory.sorted { $0.tier.rawValue < $1.tier.rawValue }
                    
                    // Find the VERY FIRST badge in this category that is NOT earned yet
                    if let nextUnearned = sortedBadges.first(where: { !$0.isEarned }) {
                        nextBadgesInLine.append(nextUnearned)
                    }
                }
                
                // 2. Finally, only show it in "Focus Challenges" if the user has actually started it (> 0)
                return nextBadgesInLine.filter { $0.currentValue > 0 }
            }
            
            // ✅ COMPLETED: Badges that have reached their goal
            var earnedBadges: [Badging.Badge] {
                return Array(milestones.filter { $0.isEarned }.reversed())
            }

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
                // ✅ ADDED [weak self] so the layout can check if your badge arrays are empty
                return UICollectionViewCompositionalLayout { [weak self] (sectionIndex, env) -> NSCollectionLayoutSection? in
                    guard let self = self, let sectionType = AwardsSection(rawValue: sectionIndex) else { return nil }
                    let hasActivity = ProgressDataManager.shared.hasEarnedAnyXP
                    
                    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(35))
                    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                    header.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

                    switch sectionType {
                    case .feature:
                        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
                        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(110)), subitems: [item])
                        let section = NSCollectionLayoutSection(group: group)
                        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
                        return section

                    case .allMilestones:
                        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(160)))
                        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
                        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(160))
                        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                        let section = NSCollectionLayoutSection(group: group)
                        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 20, trailing: 10)
                        section.boundarySupplementaryItems = [header]
                        section.supplementariesFollowContentInsets = false
                        return section

                    default: // activeChallenges and recentWins
                        // ✅ 1. Determine if this specific section is empty
                        var isEmpty = false
                        if sectionType == .activeChallenges {
                            isEmpty = !hasActivity || self.activeBadges.isEmpty
                        } else if sectionType == .recentWins {
                            isEmpty = !hasActivity || self.earnedBadges.isEmpty
                        }
                        
                        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
                        
                        // ✅ 2. DYNAMIC WIDTH: Full width (1.0) if empty so text can center, otherwise Card size (0.42)
                        let currentWidth: NSCollectionLayoutDimension = isEmpty ? .fractionalWidth(1.0) : .fractionalWidth(0.42)
                        
                        let groupSize = NSCollectionLayoutSize(widthDimension: currentWidth, heightDimension: .absolute(145))
                        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                        
                        let section = NSCollectionLayoutSection(group: group)
                        
                        // ✅ 3. Disable scrolling if it's the empty state text
                        section.orthogonalScrollingBehavior = isEmpty ? .none : .continuous
                        section.interGroupSpacing = 16
                        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 16, trailing: 16)
                        section.boundarySupplementaryItems = [header]
                        section.supplementariesFollowContentInsets = false
                        return section
                    }
                }
            }
            
            func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                let type = AwardsSection(rawValue: section)!
                let hasActivity = ProgressDataManager.shared.hasEarnedAnyXP
                
                switch type {
                case .feature:
                    return 1
                    
                case .activeChallenges:
                    if !hasActivity || activeBadges.isEmpty { return 1 }
                    return activeBadges.count
                    
                case .recentWins:
                    if !hasActivity || earnedBadges.isEmpty { return 1 }
                    return earnedBadges.count
                    
                case .allMilestones:
                    return milestones.count
                }
            }

            func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                let sectionType = AwardsSection(rawValue: indexPath.section)!
                let hasActivity = ProgressDataManager.shared.hasEarnedAnyXP

                switch sectionType {
                case .feature:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthlyFeatureCell", for: indexPath) as! MonthlyBadgeCollectionViewCell
                    cell.configure(with: milestones[0])
                    
                    // ✅ Tells the cell to send the tap to this ViewController
                    cell.delegate = self
                    
                    return cell
                    
                case .activeChallenges:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell", for: indexPath) as! BadgeCollectionViewCell
                    if !hasActivity || activeBadges.isEmpty {
                        cell.showEmptyState(section: .activeChallenges)
                    } else {
                        cell.badgeCardView.isHidden = false
                        cell.configure(with: activeBadges[indexPath.row], forSection: .activeChallenges)
                    }
                    return cell
                    
                case .recentWins:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell", for: indexPath) as! BadgeCollectionViewCell
                    if !hasActivity || earnedBadges.isEmpty {
                        cell.showEmptyState(section: .recentWins)
                    } else {
                        cell.badgeCardView.isHidden = false
                        cell.configure(with: earnedBadges[indexPath.row], forSection: .recentWins)
                    }
                    return cell
                    
                case .allMilestones:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell", for: indexPath) as! BadgeCollectionViewCell
                    cell.badgeCardView.isHidden = false
                    cell.configure(with: milestones[indexPath.row], forSection: .allMilestones)
                    return cell
                }
            }

            func numberOfSections(in collectionView: UICollectionView) -> Int { return AwardsSection.allCases.count }

            func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as! SectionHeaderView
                let titles = ["", "Focus Challenges", "Recent Achievements", "All Milestones"]
                header.titleLabel.text = titles[indexPath.section]
                return header
            }
        }

        extension AwardsViewController: MonthlyBadgeCellDelegate {

            func didTapMonthlyBadgeCard() {
                let vc = MonthlyChallengeDetailViewController(nibName: "MonthlyChallengeDetailViewController", bundle: nil)
                navigationController?.pushViewController(vc, animated: true)
            }

            func didTapShowAllButton() {
                // Reserved for future use
            }

            // ⓘ button on the feature cell — pushes XP Details screen
            func didTapXPInfo() {
                let vc = XPDetailsViewController(nibName: "XPDetailsViewController", bundle: nil)
                navigationController?.pushViewController(vc, animated: true)
            }
        }

























