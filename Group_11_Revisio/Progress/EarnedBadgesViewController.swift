//
//  EarnedBadgesViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 06/03/26.
//


import UIKit

class EarnedBadgesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Data
    private var earnedBadges: [Badging.Badge] = []

    // MARK: - UI
    private var collectionView: UICollectionView!
    private let emptyLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationItem.title = "Earned Badges"
        loadData()
        setupCollectionView()
        setupEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        collectionView.reloadData()
        emptyLabel.isHidden = !earnedBadges.isEmpty
    }

    // MARK: - Data

    private func loadData() {
        earnedBadges = Array(BadgeData.allMilestones.filter { $0.isEarned }.reversed())
    }

    // MARK: - Layout

    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask  = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor   = .black
        collectionView.dataSource        = self
        collectionView.delegate          = self
        collectionView.register(UINib(nibName: "AllBadgesCollectionViewCell", bundle: nil),
                                forCellWithReuseIdentifier: "AllBadgesCell")
        view.addSubview(collectionView)
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                               heightDimension: .absolute(160))
        let item      = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(160))
        let group     = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section   = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 10, bottom: 20, trailing: 10)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupEmptyState() {
        emptyLabel.text          = "No badges earned yet.\nKeep studying to unlock them! 🏆"
        emptyLabel.font          = .systemFont(ofSize: 16, weight: .regular)
        emptyLabel.textColor     = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.isHidden      = !earnedBadges.isEmpty
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return earnedBadges.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AllBadgesCell",
                                                      for: indexPath) as! AllBadgesCollectionViewCell
        cell.configure(with: earnedBadges[indexPath.row])
        return cell
    }
}
