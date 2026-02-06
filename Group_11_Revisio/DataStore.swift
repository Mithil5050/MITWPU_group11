import Foundation

// MARK: - Models (Ensure Source and Topic are defined in your project)
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
    
    // MARK: - Fetch Helper (✅ FIXED ORDER)
    func getAllRecentTopics() -> [Topic] {
        var allTopics: [Topic] = []
        
        // 1. Collect all topics from all folders
        for subjectData in savedMaterials.values {
            if let materials = subjectData[DataManager.materialsKey] {
                for item in materials {
                    if case .topic(let topic) = item {
                        allTopics.append(topic)
                    }
                }
            }
        }
        
        // 2. ✅ SORT: "Just now" -> Minutes -> Hours -> Days -> Older
        return allTopics.sorted { t1, t2 in
            func score(_ s: String) -> Int {
                let lower = s.lowercased()
                if lower.contains("just now") { return 0 }
                if lower.contains("sec") { return 1 }
                if lower.contains("min") { return 2 }
                if lower.contains("hour") || lower.contains("h ago") { return 3 }
                if lower.contains("day") || lower.contains("d ago") { return 4 }
                if lower.contains("week") || lower.contains("w ago") { return 5 }
                return 6 // "Never" or others
            }
            return score(t1.lastAccessed) < score(t2.lastAccessed)
        }
    }
    
    // MARK: - File Import Logic
    // Call this function from your UploadConfirmationViewController
    func importFile(url: URL, subject: String) {
        let fileManager = FileManager.default
        // Get the app's Documents directory
        let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Determine the final destination path
        let destURL = docDir.appendingPathComponent(url.lastPathComponent)
        
        do {
            // 1. Clean up if a file with the same name already exists
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            
            // 2. Securely copy the file (Critical for iOS Security Scopes)
            let accessing = url.startAccessingSecurityScopedResource()
            try fileManager.copyItem(at: url, to: destURL)
            if accessing { url.stopAccessingSecurityScopedResource() }
            
            print("✅ File physically copied to: \(destURL.path)")
            
            // 3. Calculate file size for the Source model
            let attr = try? fileManager.attributesOfItem(atPath: destURL.path)
            let fileSize = attr?[.size] as? Int64 ?? 0
            let sizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            
            // 4. Create the Source object
            // This matches the structure used in your setupDefaultData
            let newSource = Source(
                name: url.lastPathComponent,
                fileType: url.pathExtension.uppercased(),
                size: sizeString
            )
            
            // 5. Save using your existing logic
            saveContent(subject: subject, content: newSource)
            
        } catch {
            print("❌ Error importing file: \(error)")
        }
    }
    
    // MARK: - Folder Management
    func addFolder(name: String) {
        // 1. Check if folder already exists to prevent overwriting
        if savedMaterials.keys.contains(name) { return }
        
        // 2. Create the new folder structure
        savedMaterials[name] = [
            DataManager.materialsKey: [],
            DataManager.sourcesKey: []
        ]
        
        // 3. Save to disk immediately
        saveToDisk()
        
        // 4. Notify all screens (Study Tab & Select Material) to update
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }
    
    // Helper to delete if you need it
    func deleteFolder(name: String) {
        savedMaterials.removeValue(forKey: name)
        saveToDisk()
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }
    
    // Wrapper functions for compatibility
    func createNewSubjectFolder(name: String) {
        addFolder(name: name)
    }
    
    func deleteSubjectFolder(name: String) {
        deleteFolder(name: name)
    }
    
    // MARK: - Persistence (Optimized)
    func saveToDisk() {
        // 1. Capture snapshot of data (Value Type copy is thread-safe)
        let dataToSave = savedMaterials
        
        // 2. Perform heavy work on Background Thread
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(dataToSave)
                try data.write(to: self.fileURL, options: .atomic)
            } catch {
                print("Error saving: \(error)")
            }
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
    
    // MARK: - Topic Management (Optimized for Updates & Speed)
    func addTopic(to subjectName: String, topic: Topic) {
        let folder = subjectName.isEmpty ? "General Study" : subjectName
        
        // 1. Create folder if missing
        if savedMaterials[folder] == nil {
            addFolder(name: folder)
        }
        
        var subjectData = savedMaterials[folder]!
        var materials = subjectData[DataManager.materialsKey] ?? []
        
        // 2. Remove existing (Move to Top Logic)
        // If a topic with this name already exists, remove it so we can re-add it at the end
        materials.removeAll { item in
            if case .topic(let t) = item {
                return t.name == topic.name && t.materialType == topic.materialType
            }
            return false
        }
        
        // 3. Append new topic (Newest goes to end of array)
        materials.append(.topic(topic))
        
        // 4. Update Memory
        subjectData[DataManager.materialsKey] = materials
        savedMaterials[folder] = subjectData
        
        // 5. NOTIFY UI IMMEDIATELY (Before Disk Save)
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        
        // 6. Save to Disk in Background
        saveToDisk()
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
            addFolder(name: subject)
        }
        
        // Remove duplicates if source
        if segmentKey == DataManager.sourcesKey, let source = content as? Source {
             savedMaterials[subject]?[segmentKey]?.removeAll(where: { item in
                 if case .source(let s) = item { return s.name == source.name }
                 return false
             })
        }
        
        savedMaterials[subject]?[segmentKey]?.append(wrappedItem)
        
        // Notify then Save
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        saveToDisk()
    }
    
    func renameSubject(oldName: String, newName: String) {
        guard oldName != newName, let data = savedMaterials[oldName] else { return }
        savedMaterials[newName] = data
        savedMaterials.removeValue(forKey: oldName)
        
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
        saveToDisk()
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
        
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        saveToDisk()
    }
    
    func moveItems(items: [Any], from sourceSubject: String, to destinationSubject: String) {
        guard sourceSubject != destinationSubject else { return }
        
        deleteItems(subjectName: sourceSubject, items: items)
        
        for item in items {
            if var topic = item as? Topic {
                topic.parentSubjectName = destinationSubject
                addTopic(to: destinationSubject, topic: topic)
                
            } else if let source = item as? Source {
                saveContent(subject: destinationSubject, content: source)
            }
        }
    }
    
    // MARK: - Content Getters & Updaters
    func getTopic(subjectName: String, topicName: String) -> Topic? {
        guard let materials = savedMaterials[subjectName]?[DataManager.materialsKey] else { return nil }
        for item in materials {
            if case .topic(let topic) = item, topic.name == topicName {
                return topic
            }
        }
        return nil
    }
    
    func getDetailedContent(for subjectName: String, topicName: String) -> String {
        guard let subjectData = savedMaterials[subjectName],
              let materials = subjectData[DataManager.materialsKey] else {
            return "Content not found."
        }
        
        for item in materials {
            if case .topic(let topic) = item, topic.name == topicName {
                // Safely unwrap optionals and return based on priority
                let body = topic.largeContentBody ?? ""
                if !body.isEmpty { return body }
                
                let notes = topic.notesContent ?? ""
                if !notes.isEmpty { return notes }
                
                let cheat = topic.cheatsheetContent ?? ""
                if !cheat.isEmpty { return cheat }
                
                return ""
            }
        }
        return "Topic not found."
    }

    func updateTopic(subjectName: String, topic: Topic) {
        guard var subjectData = savedMaterials[subjectName] else { return }
        var materials = subjectData[DataManager.materialsKey] ?? []
        
        if let index = materials.firstIndex(where: { item in
            if case .topic(let t) = item { return t.name == topic.name }
            return false
        }) {
            materials[index] = .topic(topic)
            subjectData[DataManager.materialsKey] = materials
            savedMaterials[subjectName] = subjectData
            
            NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
            saveToDisk()
        }
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
                    
                    NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
                    saveToDisk()
                    return
                }
            }
        }
    }
    
    // MARK: - Defaults
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
}

// MARK: - Notifications
extension Notification.Name {
    static let didUpdateStudyMaterials = Notification.Name("didUpdateStudyMaterials")
    static let didUpdateStudyFolders = Notification.Name("didUpdateStudyFolders")
}

