//
//  AllLockedBadgesViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 08/03/26.
//

import UIKit

class AllLockedBadgesViewController: UIViewController,
                                     UICollectionViewDataSource,
                                     UICollectionViewDelegate {

    private var badges: [Badging.Badge] = Badging.allMilestones
    private var collectionView: UICollectionView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Adaptive: white in light mode, near-black in dark mode
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = "All Milestones"
        setupCollectionView()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: .xpDidUpdate,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Data Refresh

    @objc private func refresh() {
        badges = Badging.allMilestones
        collectionView?.reloadData()
    }

    // MARK: - Collection View Setup

    private func setupCollectionView() {
        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: createLayout()
        )
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Adaptive: matches the view background in both light and dark
        collectionView.backgroundColor  = .systemGroupedBackground
        collectionView.dataSource       = self
        collectionView.delegate         = self

        collectionView.register(
            UINib(nibName: "BadgeCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "BadgeCell"
        )
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "HeaderView"
        )

        view.addSubview(collectionView)
    }

    // MARK: - Layout

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .absolute(160)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(160)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [header]
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 24, trailing: 10)

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Helpers

    // One section per BadgeCategory, preserving the order defined in BadgeCategory
    private var categories: [Badging.BadgeCategory] {
        return Badging.BadgeCategory.allCases.filter { category in
            badges.contains { $0.category == category }
        }
    }

    private func badges(for section: Int) -> [Badging.Badge] {
        let category = categories[section]
        return badges
            .filter { $0.category == category }
            .sorted { $0.tier.rawValue < $1.tier.rawValue }  // bronze → silver → gold
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return categories.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return badges(for: section).count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "BadgeCell", for: indexPath
        ) as! BadgeCollectionViewCell
        let badge = badges(for: indexPath.section)[indexPath.item]
        cell.badgeCardView.isHidden = false
        cell.configure(with: badge, forSection: .allMilestones)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "HeaderView",
            for: indexPath
        ) as! SectionHeaderView

        header.titleLabel.text      = categories[indexPath.section].rawValue
        header.titleLabel.textColor = .label   // adaptive: dark in light mode, white in dark mode
        header.showAllHandler       = nil      // no "Show All" button on this screen
        return header
    }
}
