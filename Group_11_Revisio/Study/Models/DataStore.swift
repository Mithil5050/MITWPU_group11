import Foundation

enum StudyItem: Codable {
    case topic(Topic)
    case source(Source)
}

class DataManager {
    static let materialsKey = "Materials"
    static let sourcesKey = "Sources"
    static let shared = DataManager()
    
    var savedMaterials: [String: [String: [StudyItem]]] = [:]
    
    private var fileURL: URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent("StudyData.json")
    }

    private init() {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            // First time ever launch
            setupDefaultData()
            saveToDisk()
        } else {
            // Authoritative load from your saved JSON
            loadFromDisk()
        }
    }

    func saveToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(savedMaterials)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Error saving: \(error)")
        }
    }

    func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            savedMaterials = try JSONDecoder().decode([String: [String: [StudyItem]]].self, from: data)
            
            // --- ADD THIS LINE TO DEBUG ---
            print("📂 LOADED FOLDERS FROM DISK: \(savedMaterials.keys)")
        } catch {
            print("Error loading: \(error)")
        }
    }

    func saveContent(subject: String, content: Any) {
        let segmentKey: String
        let wrappedItem: StudyItem
        
        if let topic = content as? Topic {
            segmentKey = DataManager.materialsKey
            wrappedItem = .topic(topic)
        } else if let source = content as? Source {
            segmentKey = DataManager.sourcesKey
            wrappedItem = .source(source)
        } else { return }

        if savedMaterials[subject] == nil {
            savedMaterials[subject] = [DataManager.materialsKey: [], DataManager.sourcesKey: []]
        }
        
        savedMaterials[subject]?[segmentKey]?.append(wrappedItem)
        saveToDisk()
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
    }

    func createNewSubjectFolder(name: String) {
        savedMaterials[name] = [DataManager.materialsKey: [], DataManager.sourcesKey: []]
        saveToDisk()
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }

    func deleteSubjectFolder(name: String) {
        savedMaterials.removeValue(forKey: name)
        saveToDisk()
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }

    func renameSubject(oldName: String, newName: String) {
        guard oldName != newName, let data = savedMaterials[oldName] else { return }
        savedMaterials[newName] = data
        savedMaterials.removeValue(forKey: oldName)
        saveToDisk()
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }

    func deleteItems(subjectName: String, items: [Any]) {
        guard var subjectData = savedMaterials[subjectName] else { return }
        var materials = subjectData[DataManager.materialsKey] ?? []
        var sources = subjectData[DataManager.sourcesKey] ?? []

        for item in items {
            if let topic = item as? Topic {
                materials.removeAll { if case .topic(let t) = $0 { return t.name == topic.name }; return false }
            } else if let source = item as? Source {
                sources.removeAll { if case .source(let s) = $0 { return s.name == source.name }; return false }
            }
        }
        
        subjectData[DataManager.materialsKey] = materials
        subjectData[DataManager.sourcesKey] = sources
        savedMaterials[subjectName] = subjectData
        saveToDisk()
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
    }

    private func setupDefaultData() {
        
        // 1. CALCULUS
        let calculusMaterials: [StudyItem] = [
            .topic(Topic(
                name: "Partial Derivatives",
                lastAccessed: "Just now",
                materialType: "Flashcards",
                largeContentBody: "What is a Partial Derivative?|A derivative of a function of several variables with respect to one variable, holding others constant.\nNotation|The curly ∂ (del) symbol is used instead of 'd'.\nFirst-Order Partial f(x,y)|fₓ means differentiating with respect to x while treating y as a constant.\nChain Rule Application|Used when the variables themselves depend on other variables (e.g., x(t) and y(t)).",
                parentSubjectName: "Calculus" // Position 5: Added to prevent crash
            )),
            .topic(Topic(
                name: "Limits",
                lastAccessed: "7h ago",
                materialType: "Quiz",
                largeContentBody: "What is the limit of 1/x as x approaches infinity?|0|1|Infinity|Undefined|0|Think of a very large denominator.\nWhat is the limit of (sin x)/x as x approaches 0?|1|0|Infinity|-1|0|This is a fundamental trig limit.",
                parentSubjectName: "Calculus"
            )),
            .topic(Topic(
                name: "Multivariable Calculus",
                lastAccessed: "4 days ago",
                materialType: "Cheatsheet",
                largeContentBody: "Formula sheet for Multivariable Calculus operations.",
                parentSubjectName: "Calculus"
            ))
        ]
        
        let calculusSources: [StudyItem] = [
            .source(Source(name: "Taylor Series PDF", fileType: "PDF", size: "1.2 mb")),
            .source(Source(name: "Prof. Leonard Channel", fileType: "Video", size: "—"))
        ]
        savedMaterials["Calculus"] = [DataManager.materialsKey: calculusMaterials, DataManager.sourcesKey: calculusSources]

        // 2. BIG DATA
        savedMaterials["Big Data"] = [
            DataManager.materialsKey: [
                .topic(Topic(name: "Hadoop Fundamentals", lastAccessed: "1h ago", materialType: "Notes", largeContentBody: "Hadoop is an open-source framework for distributed storage.", parentSubjectName: "Big Data")),
                .topic(Topic(name: "NoSQL Databases", lastAccessed: "3d ago", materialType: "Quiz", largeContentBody: "Which NoSQL type is best for relationships?|Graph|Document|Key-Value|Column|0|Think of social network structures.", parentSubjectName: "Big Data"))
            ],
            DataManager.sourcesKey: [
                .source(Source(name: "Hadoop Docs", fileType: "Link", size: "—"))
            ]
        ]

        // 3. COMPUTER NETWORKS
        savedMaterials["Computer Networks"] = [
            DataManager.materialsKey: [
                .topic(Topic(name: "OSI Model", lastAccessed: "1 day ago", materialType: "Quiz", largeContentBody: "Which layer is responsible for routing?|Network|Data Link|Transport|Physical|0|IP addresses live here.", parentSubjectName: "Computer Networks")),
                .topic(Topic(name: "TCP vs UDP", lastAccessed: "3 days ago", materialType: "Flashcards", largeContentBody: "TCP|Connection-oriented and reliable.\nUDP|Connectionless and fast.", parentSubjectName: "Computer Networks"))
            ],
            DataManager.sourcesKey: []
        ]

        // 4. MMA
        savedMaterials["MMA"] = [
            DataManager.materialsKey: [
                .topic(Topic(name: "8051 Architecture", lastAccessed: "2 days ago", materialType: "Flashcards", largeContentBody: "8051 Data Bus size?|8-bit.\n8051 Address Bus size?|16-bit.", parentSubjectName: "MMA")),
                .topic(Topic(name: "Interrupt Handling", lastAccessed: "4 days ago", materialType: "Notes", largeContentBody: "Hardware interrupts stop the CPU execution immediately.", parentSubjectName: "MMA"))
            ],
            DataManager.sourcesKey: [
                .source(Source(name: "Assembly Guide", fileType: "PDF", size: "5.1 mb"))
            ]
        ]
        
        migrateHardcodedQuizzes()
    }
    func getDetailedContent(for subjectName: String, topicName: String) -> String {
        guard let subjectData = savedMaterials[subjectName],
              let materials = subjectData[DataManager.materialsKey] else {
            return "Content not found."
        }
        
        for item in materials {
            if case .topic(let topic) = item, topic.name == topicName {
                return topic.largeContentBody ?? "No content available yet."
            }
        }
        return "Topic not found."
    }

    func updateTopicContent(subject: String, topicName: String, newText: String) {
        guard var materials = savedMaterials[subject]?[DataManager.materialsKey] else { return }
        
        for (index, item) in materials.enumerated() {
            if case .topic(var topic) = item, topic.name == topicName {
                topic.largeContentBody = newText
                materials[index] = .topic(topic)
                break
            }
        }
        
        savedMaterials[subject]?[DataManager.materialsKey] = materials
        saveToDisk()
    }
    func migrateHardcodedQuizzes() {
        for (sourceName, questions) in QuizManager.quizDataBySource {
            let contentString = questions.map { q in
                let answers = q.answers.joined(separator: "|")
                return "\(q.questionText)|\(answers)|\(q.correctAnswerIndex)|\(q.hint)"
            }.joined(separator: "\n")
            
            // Match your Topic.swift order exactly:
            let newTopic = Topic(
                name: sourceName,
                lastAccessed: "Never",
                materialType: "Quiz",
                largeContentBody: contentString,     // contentBody is now 4th
                parentSubjectName: "General Study"   // parentSubjectName is now 5th
            )
            
            self.addTopic(to: "General Study", topic: newTopic)
        }
    }
    func addTopic(to subjectName: String, topic: Topic) {
       
        if savedMaterials[subjectName] == nil {
            savedMaterials[subjectName] = [DataManager.materialsKey: [], DataManager.sourcesKey: []]
        }
        
       
        savedMaterials[subjectName]?[DataManager.materialsKey]?.append(.topic(topic))
        
        
        saveToDisk()
        
       
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
    }
}

extension Notification.Name {
    static let didUpdateStudyMaterials = Notification.Name("didUpdateStudyMaterials")
    static let didUpdateStudyFolders = Notification.Name("didUpdateStudyFolders")
}
