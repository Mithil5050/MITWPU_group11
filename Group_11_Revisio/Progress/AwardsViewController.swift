//
//  AwardsViewController.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import UIKit

class AwardsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MonthlyBadgeCellDelegate {
    
    @IBOutlet weak var featuredCollectionView: UICollectionView!
    @IBOutlet weak var gridCollectionView: UICollectionView!
    
    
        var badges: [Badge] = BadgeData.allBadges
        
        private let sidePadding: CGFloat = 20.0
        private let horizontalSpacing: CGFloat = 16.0
        private let verticalSpacing: CGFloat = 20.0
        private let cardHeightToWidthRatio: CGFloat = 1.1
        private let featuredCardHeight: CGFloat = 125.0
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupCollectionViews()
            registerCells()
            setupLayouts()
            navigationItem.title = "Awards"
            
            // Listen for XP updates to refresh the "Go For It" card
            NotificationCenter.default.addObserver(self, selector: #selector(refreshAwardsData), name: .xpDidUpdate, object: nil)
        }
        
        @objc func refreshAwardsData() {
            DispatchQueue.main.async {
                self.featuredCollectionView.reloadData()
            }
        }
        
        private func setupCollectionViews() {
            featuredCollectionView.dataSource = self
            featuredCollectionView.delegate = self
            gridCollectionView.dataSource = self
            gridCollectionView.delegate = self
            featuredCollectionView.clipsToBounds = false
        }
        
        func registerCells() {
            // ✅ REGISTER TOP CELL
            featuredCollectionView.register(UINib(nibName: "MonthlyBadgeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "MonthlyFeatureCell")
            
            // ✅ REGISTER BOTTOM CELL
            gridCollectionView.register(UINib(nibName: "BadgeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BadgeCell")
            
            // ✅ REGISTER HEADER
            gridCollectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
        }
        
        func setupLayouts() {
            if let gridLayout = gridCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                gridLayout.minimumInteritemSpacing = horizontalSpacing
                gridLayout.minimumLineSpacing = verticalSpacing
                gridLayout.sectionInset = UIEdgeInsets(top: 10, left: sidePadding, bottom: 20, right: sidePadding)
                gridLayout.headerReferenceSize = CGSize(width: view.frame.width, height: 50)
            }
        }

        // MARK: - CollectionView DataSource
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return collectionView == featuredCollectionView ? 1 : badges.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            if collectionView == featuredCollectionView {
                // ✅ Matches the identifier registered in registerCells()
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthlyFeatureCell", for: indexPath) as! MonthlyBadgeCollectionViewCell
                cell.delegate = self
                cell.configure(with: badges[0])
                return cell
            } else {
                // ✅ Matches the identifier registered in registerCells()
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell", for: indexPath) as! BadgeCollectionViewCell
                cell.configure(with: badges[indexPath.row])
                return cell
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            if kind == UICollectionView.elementKindSectionHeader && collectionView == gridCollectionView {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as! SectionHeaderView
                header.onShowAllTapped = { [weak self] in
                    self?.didTapShowAllButton()
                }
                return header
            }
            return UICollectionReusableView()
        }
        
        func didTapShowAllButton() {
            // Ensure this identifier matches your Storyboard segue identifier
            self.performSegue(withIdentifier: "ShowAllBadges", sender: self)
        }
        
        func didTapMonthlyBadgeCard() {
            let detailVC = MonthlyChallengeDetailViewController(nibName: "MonthlyChallengeDetailViewController", bundle: nil)
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    // MARK: - Delegate Flow Layout
    extension AwardsViewController: UICollectionViewDelegateFlowLayout {
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            if collectionView == featuredCollectionView {
                return CGSize(width: collectionView.frame.width, height: featuredCardHeight)
            } else {
                let totalSpacing = (sidePadding * 2) + horizontalSpacing
                let width = floor((collectionView.bounds.width - totalSpacing) / 2)
                return CGSize(width: width, height: width * cardHeightToWidthRatio)
            }
        }
    }

    // MARK: - Section Header Class
    // Ensure this is OUTSIDE the AwardsViewController class braces
    class SectionHeaderView: UICollectionReusableView {
        let titleLabel = UILabel()
        let showAllButton = UIButton(type: .system)
        var onShowAllTapped: (() -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupHeader()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupHeader()
        }

        private func setupHeader() {
            titleLabel.text = "In Progress"
            titleLabel.textColor = .white
            titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
            
            showAllButton.setTitle("Show All", for: .normal)
            showAllButton.setTitleColor(.systemBlue, for: .normal)
            showAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            showAllButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
            
            addSubview(titleLabel)
            addSubview(showAllButton)
            
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            showAllButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                showAllButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                showAllButton.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
        
        @objc private func buttonTapped() {
            onShowAllTapped?()
        }
    }
