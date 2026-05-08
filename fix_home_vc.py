import re

with open("Group_11_Revisio/Home/HomeScreen/HomeViewController.swift", "r") as f:
    content = f.read()

# Replace layout for .continueLearning
old_layout = """            case .continueLearning:
                let rowHeight: CGFloat = 75
                let countToShow = isLearningExpanded ? learningItems.count : min(learningItems.count, 2)
                let totalHeight = CGFloat(max(countToShow, 1)) * rowHeight
                
                let size = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: .absolute(totalHeight))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: 5, trailing: horizontalPadding)
                section.boundarySupplementaryItems = [headerItem]
                return section"""

new_layout = """            case .continueLearning:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.85), heightDimension: .absolute(160))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPaging
                section.interGroupSpacing = 16
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: horizontalPadding, bottom: 16, trailing: horizontalPadding)
                section.boundarySupplementaryItems = [headerItem]
                return section"""

content = content.replace(old_layout, new_layout)

# Replace numberOfItemsInSection
old_num_items = """    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = HomeSection.allCases[section]
        switch sectionType {
        case .hero: return heroData.count
        default: return 1
        }
    }"""

new_num_items = """    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = HomeSection.allCases[section]
        switch sectionType {
        case .hero: return heroData.count
        case .continueLearning: return max(learningItems.count, 1)
        default: return 1
        }
    }"""

content = content.replace(old_num_items, new_num_items)

# Replace cellForItemAt for .continueLearning
old_cell = """        case .continueLearning:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: continueLearningCellID, for: indexPath) as! ContinueLearningCollectionViewCell
            let itemsToShow = isLearningExpanded ? learningItems : Array(learningItems.prefix(2))
            cell.configure(with: itemsToShow)
            cell.delegate = self
            return cell"""

new_cell = """        case .continueLearning:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: continueLearningCellID, for: indexPath) as! ContinueLearningCollectionViewCell
            if learningItems.isEmpty {
                cell.configureAsEmpty()
            } else {
                cell.configure(with: learningItems[indexPath.row])
            }
            cell.delegate = self
            return cell"""

content = content.replace(old_cell, new_cell)

with open("Group_11_Revisio/Home/HomeScreen/HomeViewController.swift", "w") as f:
    f.write(content)
