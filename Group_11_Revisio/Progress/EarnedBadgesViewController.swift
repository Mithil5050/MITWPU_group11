
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
        earnedBadges = Array(Badging.allMilestones.filter { $0.isEarned }.reversed())
    }

    // MARK: - Layout

    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor  = .black
        collectionView.dataSource       = self
        collectionView.delegate         = self
        collectionView.register(UINib(nibName: "BadgeCollectionViewCell", bundle: nil),
                                forCellWithReuseIdentifier: "BadgeCell")
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
        // 1. Configure the text label (removing the emoji from the string)
        emptyLabel.text = "No badges earned yet.\nKeep studying to unlock them!"
        emptyLabel.font = .systemFont(ofSize: 16, weight: .regular)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 2. Create the Badge Image View (SF Symbol)
        let badgeImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        badgeImageView.image = UIImage(systemName: "trophy", withConfiguration: config)
        badgeImageView.tintColor = .secondaryLabel
        badgeImageView.contentMode = .scaleAspectFit
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. Add subviews
        view.addSubview(emptyLabel)
        view.addSubview(badgeImageView)
        
        // 4. Setup Constraints (Positioning the image view below the text)
        NSLayoutConstraint.activate([
            // Center the label in the view
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // Position the Trophy Icon directly below the text
            badgeImageView.topAnchor.constraint(equalTo: emptyLabel.bottomAnchor, constant: 12),
            badgeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            badgeImageView.widthAnchor.constraint(equalToConstant: 40),
            badgeImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Logic from your screenshot to handle visibility
        let noBadges = earnedBadges.isEmpty
        emptyLabel.isHidden = !noBadges
        badgeImageView.isHidden = !noBadges
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return earnedBadges.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell",
                                                      for: indexPath) as! BadgeCollectionViewCell
        cell.configure(with: earnedBadges[indexPath.row], forSection: .allMilestones)
        return cell
    }
}
