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
        loadFromDisk()
        
        // If we loaded nothing (either file didn't exist or was corrupt), setup defaults
        if savedMaterials.isEmpty {
            setupDefaultData()
            saveToDisk()
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
            
           
            print(" LOADED FOLDERS FROM DISK: \(savedMaterials.keys)")
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
                materials.removeAll { if case .topic(let t) = $0 {
                    return t.name == topic.name && t.materialType == topic.materialType
                }; return false }
            } else if let source = item as? Source {
                sources.removeAll { if case .source(let s) = $0 {
                    return s.name == source.name && s.fileType == source.fileType
                }; return false }
            }
        }
        
        subjectData[DataManager.materialsKey] = materials
        subjectData[DataManager.sourcesKey] = sources
        savedMaterials[subjectName] = subjectData
        saveToDisk()
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
    }
    
    private func setupDefaultData() {
        
        let calculusMaterials: [StudyItem] = [
            .topic(Topic(
                name: "Partial Derivatives",
                lastAccessed: "Just now",
                materialType: "Flashcards",
                largeContentBody: "What is a Partial Derivative?|A derivative of a function of several variables",
                parentSubjectName: "Calculus"
            )),
            .topic(Topic(
                name: "Limits",
                lastAccessed: "7h ago",
                materialType: "Quiz",
                largeContentBody: """
    What is the limit of (sin x)/x as x approaches 0?|0|1|Infinity|Undefined|1|This is a special trigonometric limit often proven by the Squeeze Theorem.
    Evaluate the limit: lim (x→2) [ (x² - 4) / (x - 2) ]|0|2|4|Does not exist|2|Factor the numerator (x² - 4) into (x - 2)(x + 2).
    What is the limit of 1/x as x approaches infinity?|0|1|Infinity|Undefined|0|Think about what happens to a fraction when the denominator becomes extremely large.
    If lim f(x)/g(x) results in 0/0, L'Hôpital's Rule allows you to calculate the limit by:|Taking the derivative of the whole fraction|Multiplying by the conjugate|Taking the derivative of the numerator and denominator separately|Dividing by the highest power of x|2|L'Hôpital's Rule states lim f(x)/g(x) = lim f'(x)/g'(x).
    A limit exists only if:|The function is defined at that point|The left-hand and right-hand limits are equal|The function is continuous|The result is a whole number|1|Check both sides: lim (x→a⁻) f(x) must equal lim (x→a⁺) f(x).
    Evaluate: lim (x→∞) [ (3x² + 5) / (x² - 2) ]|0|Infinity|3|5|2|For limits at infinity of rational functions, compare leading coefficients.
    """,
                parentSubjectName: "Calculus"
            )),
            .topic(Topic(
                name: "Taylor Series PDF",
                lastAccessed: "Just now",
                materialType: "Notes",
                largeContentBody: "Taylor Series approximation for smooth functions.",
                parentSubjectName: "Calculus",
                notesContent: "--- NOTES ---\n\nTaylor Series represent functions as infinite sums of terms calculated from derivatives.\n\n1. Definition: f(x) = f(a) + f'(a)(x-a) + f''(a)/2! * (x-a)^2...\n2. Importance: Crucial for approximating complex functions like sin(x) or e^x.",
                cheatsheetContent: "--- CHEATSHEET ---\n\n• Formula: Σ [f^(n)(a) / n!] * (x-a)^n\n• Maclaurin: Series centered at a=0.\n• e^x: 1 + x + x²/2! + x³/3!...\n• sin(x): x - x³/3! + x⁵/5!..."
            ))
        ]
        
        let calculusSources: [StudyItem] = [
            .source(Source(name: "Taylor Series PDF", fileType: "PDF", size: "1.2 mb")),
            .source(Source(name: "Prof. Leonard Channel", fileType: "Video", size: "—"))
        ]
        savedMaterials["Calculus"] = [DataManager.materialsKey: calculusMaterials, DataManager.sourcesKey: calculusSources]
        
        savedMaterials["Big Data"] = [
            DataManager.materialsKey: [
                .topic(Topic(
                    name: "Hadoop Fundamentals",
                    lastAccessed: "1h ago",
                    materialType: "Notes",
                    largeContentBody: "Hadoop is an open-source framework for distributed storage.",
                    parentSubjectName: "Big Data",
                    notesContent: "--- NOTES ---\n\nHadoop allows for the distributed processing of large data sets across clusters of computers.\n\n1. HDFS: Distributed Storage.\n2. MapReduce: Parallel Processing.",
                    cheatsheetContent: "--- CHEATSHEET ---\n\n• 3 Pillars: HDFS, MapReduce, YARN.\n• Fault Tolerance: Data is replicated 3x default."
                )),
                .topic(Topic(
                    name: "Hadoop Docs",
                    lastAccessed: "Just now",
                    materialType: "Flashcards",
                    largeContentBody: "HDFS|Hadoop Distributed File System for storing large files.\nMapReduce|A programming model for processing large data sets.\nYARN|Yet Another Resource Negotiator for scheduling.\nNameNode|The centerpiece of an HDFS file system.",
                    parentSubjectName: "Big Data"
                )),
                .topic(Topic(
                    name: "NoSQL Databases",
                    lastAccessed: "3d ago",
                    materialType: "Quiz",
                    largeContentBody: """
    Which NoSQL type is best for storing social media relationships?|Document|Key-Value|Graph|Column-family|2|Graph databases like Neo4j are designed specifically for relationship-heavy data.
    What does the 'A' in the CAP theorem stand for?|Acidity|Availability|Atomicity|Aggregation|1|CAP theorem stands for Consistency, Availability, and Partition Tolerance.
    Which database is an example of a Document Store?|MySQL|Redis|MongoDB|Cassandra|2|MongoDB stores data in JSON-like BSON documents.
    """,
                    parentSubjectName: "Big Data"
                ))
            ],
            DataManager.sourcesKey: [
                .source(Source(name: "Hadoop Docs", fileType: "Link", size: "—"))
            ]
        ]
        
        savedMaterials["Computer Networks"] = [
            DataManager.materialsKey: [
                .topic(Topic(
                    name: "OSI Model",
                    lastAccessed: "1 day ago",
                    materialType: "Quiz",
                    largeContentBody: """
    Which layer is responsible for routing packets across different networks?|Data Link|Transport|Network|Session|2|The Network layer (Layer 3) handles IP addressing and routing.
    Which device operates primarily at the Data Link layer?|Hub|Switch|Router|Repeater|1|Switches use MAC addresses to forward data at Layer 2.
    Which protocol operates at the Application layer?|IP|TCP|HTTP|UDP|2|HTTP, FTP, and SMTP are all top-level Application layer protocols.
    """,
                    parentSubjectName: "Computer Networks"
                )),
                .topic(Topic(
                    name: "TCP vs UDP",
                    lastAccessed: "3 days ago",
                    materialType: "Flashcards",
                    largeContentBody: "TCP|Reliable connection-oriented.\nUDP|Fast connectionless.",
                    parentSubjectName: "Computer Networks"
                ))
            ],
            DataManager.sourcesKey: []
        ]
        
        savedMaterials["MMA"] = [
            DataManager.materialsKey: [
                .topic(Topic(
                    name: "8051 Architecture",
                    lastAccessed: "2 days ago",
                    materialType: "Flashcards",
                    largeContentBody: "8051 Data Bus size?|8-bit.\nAddress Bus size?|16-bit.",
                    parentSubjectName: "MMA"
                )),
                .topic(Topic(
                    name: "Interrupt Handling",
                    lastAccessed: "4 days ago",
                    materialType: "Notes",
                    largeContentBody: "Hardware interrupts stop CPU execution.",
                    parentSubjectName: "MMA"
                ))
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
    
    func updateTopicContent(subject: String, topicName: String, newText: String, type: String = "Notes") {
        guard var materials = savedMaterials[subject]?[DataManager.materialsKey] else { return }
        
        for (index, item) in materials.enumerated() {
            if case .topic(var topic) = item, topic.name == topicName {
                if type == "Notes" {
                    topic.notesContent = newText
                } else if type == "Cheatsheet" {
                    topic.cheatsheetContent = newText
                } else if type == "Flashcards" {
                    topic.largeContentBody = newText
                } else {
                    topic.largeContentBody = newText
                }
                
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
            
            
            let newTopic = Topic(
                name: sourceName,
                lastAccessed: "Never",
                materialType: "Quiz",
                largeContentBody: contentString,
                parentSubjectName: "General Study"
            )
            
            self.addTopic(to: "General Study", topic: newTopic)
        }
    }
    func addTopic(to subjectName: String, topic: Topic) {
        if savedMaterials[subjectName] == nil {
            savedMaterials[subjectName] = [DataManager.materialsKey: [], DataManager.sourcesKey: []]
        }
        
       
        let alreadyExists = savedMaterials[subjectName]?[DataManager.materialsKey]?.contains(where: { item in
            if case .topic(let existingTopic) = item {
                return existingTopic.name == topic.name && existingTopic.materialType == topic.materialType
            }
            return false
        }) ?? false
        
        
        if !alreadyExists {
            savedMaterials[subjectName]?[DataManager.materialsKey]?.append(.topic(topic))
            saveToDisk()
            
            
            NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        }
    }
    func renameMaterial(subjectName: String, item: Any, newName: String) {
        guard var subjectDict = savedMaterials[subjectName] else { return }
        
        let keys = [DataManager.materialsKey, DataManager.sourcesKey]
        
        for key in keys {
            if var items = subjectDict[key] as? [StudyItem] {
                if let index = items.firstIndex(where: { existingItem in
                    switch (existingItem, item) {
                    case (.topic(let t1), let t2 as Topic): return t1.name == t2.name
                    case (.source(let s1), let s2 as Source): return s1.name == s2.name
                    default: return false
                    }
                }) {
                    let updatedItem: StudyItem
                    switch items[index] {
                    case .topic(var topic):
                        topic.name = newName
                        updatedItem = .topic(topic)
                    case .source(var source):
                        source.name = newName
                        updatedItem = .source(source)
                    }
                    
                    items[index] = updatedItem
                    subjectDict[key] = items
                    savedMaterials[subjectName] = subjectDict
                    saveToDisk()
                    return
                }
            }
        }
    }
    func moveItems(items: [Any], from sourceSubject: String, to destinationSubject: String) {
        guard sourceSubject != destinationSubject else { return }
        
        deleteItems(subjectName: sourceSubject, items: items)
        
        for item in items {
            if var topic = item as? Topic {
                topic.parentSubjectName = destinationSubject
                addTopic(to: destinationSubject, topic: topic)
                
            } else if let source = item as? Source {
                if savedMaterials[destinationSubject] == nil {
                    savedMaterials[destinationSubject] = [DataManager.materialsKey: [], DataManager.sourcesKey: []]
                }
                savedMaterials[destinationSubject]?[DataManager.sourcesKey]?.append(.source(source))
            }
        }
        
        saveToDisk()
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
    }
    func getTopic(subjectName: String, topicName: String) -> Topic? {
        guard let materials = savedMaterials[subjectName]?[DataManager.materialsKey] else { return nil }
        for item in materials {
            if case .topic(let topic) = item, topic.name == topicName {
                return topic
            }
        }
        return nil
    }

    func updateTopic(subjectName: String, topic: Topic) {
        // 1. Get the subject's full data (Materials and Sources)
        guard var subjectData = savedMaterials[subjectName] else { return }
        
        // 2. Get the materials array
        var materials = subjectData[DataManager.materialsKey] ?? []
        
        // 3. Find and replace the topic
        if let index = materials.firstIndex(where: { item in
            if case .topic(let t) = item { return t.name == topic.name }
            return false
        }) {
            materials[index] = .topic(topic)
            
            // 4. ESSENTIAL: Re-assign all the way back up the chain
            subjectData[DataManager.materialsKey] = materials
            savedMaterials[subjectName] = subjectData
            
            saveToDisk()
            NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        }
    }
}

extension Notification.Name {
    static let didUpdateStudyMaterials = Notification.Name("didUpdateStudyMaterials")
    static let didUpdateStudyFolders = Notification.Name("didUpdateStudyFolders")
}
