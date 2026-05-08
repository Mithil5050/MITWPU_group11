with open("Group_11_Revisio/Home/HomeScreen/HomeViewController.swift", "r") as f:
    content = f.read()

content = content.replace(
    'collectionView.register(UINib(nibName: "ContinueLearningCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: continueLearningCellID)',
    'collectionView.register(ContinueLearningCollectionViewCell.self, forCellWithReuseIdentifier: continueLearningCellID)'
)

with open("Group_11_Revisio/Home/HomeScreen/HomeViewController.swift", "w") as f:
    f.write(content)
