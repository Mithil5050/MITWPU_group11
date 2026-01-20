//
//  AwardsViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import UIKit

// NOTE: The Badge struct must be available (e.g., defined in DataModels.swift)

class AwardsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MonthlyBadgeCellDelegate {
    
    // MARK: - Outlets (Similar to your example's single CollectionView outlet)
    @IBOutlet weak var featuredCollectionView: UICollectionView!
    @IBOutlet weak var gridCollectionView: UICollectionView!
    
    var badges: [Badge] = BadgeData.allBadges
    
    private let sidePadding: CGFloat = 20.0
    private let horizontalSpacing: CGFloat = 16.0
    private let verticalSpacing: CGFloat = 20.0
    private let numberOfColumns: CGFloat = 2.0
    private let cardHeightToWidthRatio: CGFloat = 1.1
    private let featuredCardHeight: CGFloat = 130.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViews()
        registerCells()
        setupLayouts()
        navigationItem.title = "Awards"
    }
    
    private func setupCollectionViews() {
        featuredCollectionView.dataSource = self
        featuredCollectionView.delegate = self
        gridCollectionView.dataSource = self
        gridCollectionView.delegate = self
    }
    
    func registerCells() {
        featuredCollectionView.register(UINib(nibName: "MonthlyBadgeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "MonthlyFeatureCell")
        gridCollectionView.register(UINib(nibName: "BadgeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BadgeGridCell")
        
        // Register the header class for the grid
        gridCollectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
    }
    
    func setupLayouts() {
        if let gridLayout = gridCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            gridLayout.minimumInteritemSpacing = horizontalSpacing
            gridLayout.minimumLineSpacing = verticalSpacing
            // Adjusted top inset to 0 because header handles its own spacing
            gridLayout.sectionInset = UIEdgeInsets(top: 0, left: sidePadding, bottom: verticalSpacing, right: sidePadding)
        }
        if let featuredLayout = featuredCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            featuredLayout.sectionInset = UIEdgeInsets(top: 0, left: sidePadding, bottom: 0, right: sidePadding)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == featuredCollectionView ? 1 : badges.count - 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == featuredCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthlyFeatureCell", for: indexPath) as? MonthlyBadgeCollectionViewCell else { fatalError() }
            cell.delegate = self
            cell.configure(with: badges[0])
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeGridCell", for: indexPath) as? BadgeCollectionViewCell else { fatalError() }
            
            // Use your existing badge data
            let badge = badges[indexPath.item + 1]
//            
//            // Pass the numeric value for the bar and the text for your label
            cell.configure(with: badge)
//            
            return cell
        }
    }
    
    // Implementation for the "In Progress" header
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader && collectionView == gridCollectionView {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as! SectionHeaderView
            header.titleLabel.text = "In Progress"
            header.subtitleLabel.text = "Awards you're close to earning"
            return header
        }
        return UICollectionReusableView()
    }
    
    // MARK: - Navigation / Segue Logic
    func didTapMonthlyBadgeCard() {
        let detailVC = MonthlyChallengeDetailViewController(nibName: "MonthlyChallengeDetailViewController", bundle: nil)
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func didTapShowAllButton() {
        self.performSegue(withIdentifier: "ShowAllBadges", sender: self)
    }
}
    // MARK: - Layout Extension
    extension AwardsViewController: UICollectionViewDelegateFlowLayout {
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            if collectionView == featuredCollectionView {
                return CGSize(width: collectionView.bounds.width - (sidePadding * 2), height: featuredCardHeight)
            } else {
                let totalSpacing = (sidePadding * 2) + horizontalSpacing
                let width = floor((collectionView.bounds.width - totalSpacing) / 2)
                return CGSize(width: width, height: width * cardHeightToWidthRatio)
            }
        }

        // Set height for the "In Progress" header
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
            if collectionView == gridCollectionView {
                return CGSize(width: collectionView.frame.width, height: 70)
            }
            return .zero
        }
    }

class SectionHeaderView: UICollectionReusableView {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel() // Add this

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHeader()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHeader()
    }

    private func setupHeader() {
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        
        subtitleLabel.textColor = .lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        
        // Use a StackView to arrange them vertically
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
