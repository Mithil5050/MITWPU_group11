with open("Group_11_Revisio/Home/HomeScreen/HomeViewController.swift", "r") as f:
    content = f.read()

content = content.replace(
    'var learningItems: [ContentItem] = []',
    'var learningItems: [Topic] = []'
)

# Update loadRecentLearningData
old_load = """            let recentTopics = Array(incompleteTasks.prefix(5))
            
            self.learningItems = recentTopics.map { topic in
                var type = topic.materialType
                if type == "Flashcards" { type = "Flashcard" }
                return ContentItem(title: topic.name, iconName: "doc.text", itemType: type)
            }
            
            DispatchQueue.main.async { self.collectionView.reloadData() }"""

new_load = """            let recentTopics = Array(incompleteTasks.prefix(5))
            self.learningItems = recentTopics
            DispatchQueue.main.async { self.collectionView.reloadData() }"""
content = content.replace(old_load, new_load)

# Update delegate extension
old_delegate = """// MARK: - Continue Learning Delegate
extension HomeViewController: ContinueLearningCellDelegate {
    func didSelectLearningItem(_ item: ContentItem) {
        let allTopics = DataManager.shared.getAllRecentTopics()
        
        guard let realTopic = allTopics.first(where: { topic in
            let nameMatches = (topic.name == item.title)
            let topicType = topic.materialType.lowercased()
            let itemType = item.itemType.lowercased()
            let typeMatches = topicType.contains(itemType) || itemType.contains(topicType)
            return nameMatches && typeMatches
        }) else { return }
        
        let typeLower = realTopic.materialType.lowercased()
        if typeLower.contains("quiz") { performSegue(withIdentifier: showQuizStartSegueID, sender: realTopic) }
        else if typeLower.contains("flashcard") { performSegue(withIdentifier: showFlashcardsSegueID, sender: realTopic) }
        else if typeLower.contains("cheatsheet") { performSegue(withIdentifier: showCheatsheetSegueID, sender: realTopic) }
        else { performSegue(withIdentifier: showNotesDetailSegueID, sender: realTopic) }
    }
}"""

new_delegate = """// MARK: - Continue Learning Delegate
extension HomeViewController: ContinueLearningCellDelegate {
    func didSelectLearningItem(_ topic: Topic) {
        let typeLower = topic.materialType.lowercased()
        if typeLower.contains("quiz") { performSegue(withIdentifier: showQuizStartSegueID, sender: topic) }
        else if typeLower.contains("flashcard") { performSegue(withIdentifier: showFlashcardsSegueID, sender: topic) }
        else if typeLower.contains("cheatsheet") { performSegue(withIdentifier: showCheatsheetSegueID, sender: topic) }
        else { performSegue(withIdentifier: showNotesDetailSegueID, sender: topic) }
    }
}"""
content = content.replace(old_delegate, new_delegate)

with open("Group_11_Revisio/Home/HomeScreen/HomeViewController.swift", "w") as f:
    f.write(content)
