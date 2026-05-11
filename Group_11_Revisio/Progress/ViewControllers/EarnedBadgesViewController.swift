
//
//  EarnedBadgesViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 06/03/26.
//

import UIKit

class EarnedBadgesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    private var earnedBadges: [Badging.Badge] = []
    private var collectionView: UICollectionView!
    private let emptyLabel = UILabel()


    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Badges"
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


    private func loadData() {
        earnedBadges = Array(Badging.allMilestones.filter { $0.isEarned }.reversed())
    }

// Layout
    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
        emptyLabel.text = "Earned Badges will appear here.\n Keep learning!"
        emptyLabel.font = .systemFont(ofSize: 16, weight: .regular)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        //Badge Image View
        let badgeImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        badgeImageView.image = UIImage(systemName: "trophy", withConfiguration: config)
        badgeImageView.tintColor = .secondaryLabel
        badgeImageView.contentMode = .scaleAspectFit
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        
    
        view.addSubview(emptyLabel)
        view.addSubview(badgeImageView)
        
        
        NSLayoutConstraint.activate([
            // Center the label in the view
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            
            
            badgeImageView.topAnchor.constraint(equalTo: emptyLabel.bottomAnchor, constant: 12),
            badgeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            badgeImageView.widthAnchor.constraint(equalToConstant: 40),
            badgeImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        
        let noBadges = earnedBadges.isEmpty
        emptyLabel.isHidden = !noBadges
        badgeImageView.isHidden = !noBadges
    }

//UICollectionViewDataSource

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
