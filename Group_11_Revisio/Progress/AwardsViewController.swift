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
    
    // Core data properties
        var activeChallenges: [Badge] = []
        var recentWins: [Badge] = []
        var milestones: [Badge] = []

    override func viewDidLoad() {
            super.viewDidLoad()
            setupData()
            setupCollectionView()
            navigationItem.title = "Awards"
            
            NotificationCenter.default.addObserver(self, selector: #selector(refreshAwardsData), name: .xpDidUpdate, object: nil)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self, name: .xpDidUpdate, object: nil)
        }
        
        @objc private func refreshAwardsData() {
            setupData()
            collectionView.reloadData()
        }

        private func setupData() {
            let allBadges = BadgeData.allBadges
            // Logic: 2 cards per heading as requested
            self.activeChallenges = Array(allBadges.prefix(2))
            self.recentWins = Array(allBadges.suffix(2))
            self.milestones = Array(BadgeData.milestoneBadges.prefix(2))
        }

        private func setupCollectionView() {
            collectionView.dataSource = self
            collectionView.delegate = self
            
            let layout = createLayout()
            layout.register(SectionBackgroundView.self, forDecorationViewOfKind: "section-background")
            collectionView.collectionViewLayout = layout
            
            // ✅ FIX: Corrected the missing argument syntax error
            collectionView.register(UINib(nibName: "MonthlyBadgeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "MonthlyFeatureCell")
            collectionView.register(UINib(nibName: "BadgeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BadgeCell")
            collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
            
            collectionView.backgroundColor = .black
        }

        private func createLayout() -> UICollectionViewLayout {
            return UICollectionViewCompositionalLayout { (sectionIndex, env) -> NSCollectionLayoutSection? in
                guard let sectionType = AwardsSection(rawValue: sectionIndex) else { return nil }
                
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(45))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

                switch sectionType {
                case .feature:
                    // Breathable Apple-style height
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(95)), subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
                    return section

                default:
                    item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
                    // Width 0.45 for exactly 2 cards
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(0.45), heightDimension: .absolute(155)), subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    section.orthogonalScrollingBehavior = .continuous
                    section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 20, trailing: 12)
                    section.boundarySupplementaryItems = [header]
                    return section
                }
            }
        }

        func numberOfSections(in collectionView: UICollectionView) -> Int { return 4 }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return [1, activeChallenges.count, recentWins.count, milestones.count][section]
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let section = AwardsSection(rawValue: indexPath.section)!
            if section == .feature {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthlyFeatureCell", for: indexPath) as! MonthlyBadgeCollectionViewCell
                cell.configure(with: BadgeData.allBadges[0])
                cell.delegate = self
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell", for: indexPath) as! BadgeCollectionViewCell
                let badgeList = [activeChallenges, recentWins, milestones][indexPath.section - 1]
                cell.configure(with: badgeList[indexPath.row], forSection: section)
                return cell
            }
        }

        func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as! SectionHeaderView
            let titles = ["", "Focus Challenges", "Recent Achievements", "All Milestones"]
            header.titleLabel.text = titles[indexPath.section]
            header.showAllButton.isHidden = true
            return header
        }
    }

    // ✅ REMOVE SectionBackgroundView.swift file and keep this one here
    class SectionBackgroundView: UICollectionReusableView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
            self.layer.cornerRadius = 16
        }
        required init?(coder: NSCoder) { fatalError() }
    }

    extension AwardsViewController: MonthlyBadgeCellDelegate {
        func didTapShowAllButton() { }
        func didTapMonthlyBadgeCard() {
            let detailVC = MonthlyChallengeDetailViewController(nibName: "MonthlyChallengeDetailViewController", bundle: nil)
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
