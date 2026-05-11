//
//  AwardsViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import UIKit

enum AwardsSection: Int, CaseIterable {
    case feature          = 0  // Large Monthly Badge / XP card
    case activeChallenges = 1  // Horizontal Scroll (closest to completion)
    case recentWins       = 2  // Horizontal Scroll (recently earned)
    case allMilestones    = 3  // "Show all" to AllLockedBadgesViewController
}

class AwardsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!

    var milestones: [Badging.Badge] = []

    // The 4 upcoming next-tier badges, ranked by how close the current tier is to completion.
    private let milestonePreviewCount = 4

    var previewMilestones: [Badging.Badge] {
        var result: [(badge: Badging.Badge, progress: Float)] = []

        for category in Badging.BadgeCategory.allCases {
            let sorted = milestones
                .filter { $0.category == category }
                .sorted { $0.tier.rawValue < $1.tier.rawValue }

            guard let activeIndex = sorted.firstIndex(where: { !$0.isEarned && $0.currentValue > 0 })
            else { continue }

            let activeBadge = sorted[activeIndex]
            let nextIndex   = activeIndex + 1

            if nextIndex < sorted.count {
                result.append((sorted[nextIndex], activeBadge.progress))
            } else if activeBadge.progress >= 0.5 {
                result.append((activeBadge, activeBadge.progress))
            }
        }

        return Array(result
            .sorted { $0.progress > $1.progress }
            .map { $0.badge }
            .prefix(milestonePreviewCount))
    }

    var activeBadges: [Badging.Badge] {
        var nextBadgesInLine: [Badging.Badge] = []
        for category in Badging.BadgeCategory.allCases {
            let badgesInCategory = milestones.filter { $0.category == category }
            let sortedBadges     = badgesInCategory.sorted { $0.tier.rawValue < $1.tier.rawValue }
            if let nextUnearned = sortedBadges.first(where: { !$0.isEarned }) {
                nextBadgesInLine.append(nextUnearned)
            }
        }
        return nextBadgesInLine.filter { $0.currentValue > 0 }
    }

    var earnedBadges: [Badging.Badge] {
        return Array(milestones.filter { $0.isEarned }.reversed())
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Adaptive background — white in light mode, dark in dark mode
        collectionView.backgroundColor = .systemGroupedBackground
        view.backgroundColor           = .systemGroupedBackground

        setupData()
        setupCollectionView()
        navigationItem.title = "Awards"

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshAwardsData),
            name: .xpDidUpdate,
            object: nil
        )
    }

    @objc private func refreshAwardsData() {
        DispatchQueue.main.async { self.collectionView.reloadData() }
    }

    private func setupData() {
        self.milestones = Badging.allMilestones
    }

    // MARK: - Collection View Setup

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate   = self
        collectionView.collectionViewLayout = createLayout()

        collectionView.register(
            UINib(nibName: "MonthlyBadgeCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "MonthlyFeatureCell"
        )
        collectionView.register(
            UINib(nibName: "BadgeCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "BadgeCell"
        )
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "HeaderView"
        )
    }

    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex, env) -> NSCollectionLayoutSection? in
            guard let self = self,
                  let sectionType = AwardsSection(rawValue: sectionIndex) else { return nil }

            let hasActivity = ProgressDataManager.shared.hasEarnedAnyXP

            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(44)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )

            switch sectionType {
            case .feature:
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .fractionalHeight(1.0))
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .absolute(110)),
                    subitems: [item]
                )
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
                return section

            case .allMilestones:
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(0.5),
                                      heightDimension: .absolute(160))
                )
                item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(160)
                )
                let group   = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 20, trailing: 10)
                section.boundarySupplementaryItems = [header]
                section.supplementariesFollowContentInsets = false
                return section

            default:
                var isEmpty = false
                if sectionType == .activeChallenges {
                    isEmpty = !hasActivity || self.activeBadges.isEmpty
                } else if sectionType == .recentWins {
                    isEmpty = !hasActivity || self.earnedBadges.isEmpty
                }

                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .fractionalHeight(1.0))
                )
                let currentWidth: NSCollectionLayoutDimension = isEmpty
                    ? .fractionalWidth(1.0)
                    : .fractionalWidth(0.42)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: currentWidth,
                    heightDimension: .absolute(145)
                )
                let group   = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = isEmpty ? .none : .continuous
                section.interGroupSpacing = 16
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 16, trailing: 16)
                section.boundarySupplementaryItems = [header]
                section.supplementariesFollowContentInsets = false
                return section
            }
        }
    }

    // MARK: - DataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return AwardsSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        let type        = AwardsSection(rawValue: section)!
        let hasActivity = ProgressDataManager.shared.hasEarnedAnyXP

        switch type {
        case .feature:          return 1
        case .activeChallenges: return (!hasActivity || activeBadges.isEmpty)  ? 1 : activeBadges.count
        case .recentWins:       return (!hasActivity || earnedBadges.isEmpty)  ? 1 : earnedBadges.count
        case .allMilestones:    return previewMilestones.isEmpty               ? 1 : previewMilestones.count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = AwardsSection(rawValue: indexPath.section)!
        let hasActivity = ProgressDataManager.shared.hasEarnedAnyXP

        switch sectionType {
        case .feature:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "MonthlyFeatureCell", for: indexPath
            ) as! MonthlyBadgeCollectionViewCell
            cell.configure(with: milestones[0])
            cell.delegate = self
            return cell

        case .activeChallenges:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "BadgeCell", for: indexPath
            ) as! BadgeCollectionViewCell
            if !hasActivity || activeBadges.isEmpty {
                cell.showEmptyState(section: .activeChallenges)
            } else {
                cell.badgeCardView.isHidden = false
                cell.configure(with: activeBadges[indexPath.row], forSection: .activeChallenges)
            }
            return cell

        case .recentWins:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "BadgeCell", for: indexPath
            ) as! BadgeCollectionViewCell
            if !hasActivity || earnedBadges.isEmpty {
                cell.showEmptyState(section: .recentWins)
            } else {
                cell.badgeCardView.isHidden = false
                cell.configure(with: earnedBadges[indexPath.row], forSection: .recentWins)
            }
            return cell

        case .allMilestones:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "BadgeCell", for: indexPath
            ) as! BadgeCollectionViewCell
            if previewMilestones.isEmpty {
                cell.showEmptyState(section: .recentWins)
            } else {
                cell.badgeCardView.isHidden = false
                cell.configure(with: previewMilestones[indexPath.row], forSection: .allMilestones)
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath
        ) as! SectionHeaderView

        let titles = ["", "Focus Challenges", "Recent Achievements", "All Milestones"]
        header.titleLabel.text      = titles[indexPath.section]
        header.titleLabel.textColor = .label   // adaptive: black in light, white in dark

        // Wire "Show All" only on the milestones header
        if indexPath.section == AwardsSection.allMilestones.rawValue {
            header.showAllHandler = { [weak self] in
                self?.openAllMilestones()
            }
        } else {
            header.showAllHandler = nil
        }

        return header
    }

    // MARK: - Navigation

    private func openAllMilestones() {
        let vc = AllLockedBadgesViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - MonthlyBadgeCellDelegate

extension AwardsViewController: MonthlyBadgeCellDelegate {

    func didTapMonthlyBadgeCard() {
        let vc = MonthlyChallengeDetailViewController(
            nibName: "MonthlyChallengeDetailViewController", bundle: nil
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    func didTapShowAllButton() { }

    func didTapXPInfo() {
        let vc = XPDetailsViewController(nibName: "XPDetailsViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
}
