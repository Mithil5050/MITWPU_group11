import Foundation
// ✅ ADD THIS IMPORT (Crucial for the cloud sync code below to work)
import Supabase

// MARK: - Models
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
        
        if savedMaterials.isEmpty {
            DispatchQueue.main.async {
                self.setupDefaultData()
                self.saveToDisk()
            }
        }
    }
    
    // MARK: - ✅ NEW: Save AI Content Function
    func saveGeneratedTopic(name: String,
                            subject: String,
                            type: String,
                            notes: String? = nil,
                            questions: [QuizQuestion]? = nil) -> Topic {
        
        let folder = subject.isEmpty ? "General Study" : subject
        
        // ✅ FIXED: Using 'notesContent' to match your Topic.swift
        let newTopic = Topic(
            name: name,
            lastAccessed: "Just now",
            materialType: type,
            parentSubjectName: folder,
            quizQuestions: questions,
            notesContent: notes  // <--- Fixed variable name here
        )
        
        addTopic(to: folder, topic: newTopic)
        print("💾 DataManager: Successfully saved \(type): \(name)")
        return newTopic
    }

    // MARK: - Fetch Helper
    func getAllRecentTopics() -> [Topic] {
        var allTopics: [Topic] = []
        for subjectData in savedMaterials.values {
            if let materials = subjectData[DataManager.materialsKey] {
                for item in materials {
                    if case .topic(let topic) = item {
                        allTopics.append(topic)
                    }
                }
            }
        }
        return allTopics.sorted { t1, t2 in
            func score(_ s: String) -> Int {
                let lower = s.lowercased()
                if lower.contains("just now") { return 0 }
                if lower.contains("sec") { return 1 }
                if lower.contains("min") { return 2 }
                if lower.contains("hour") || lower.contains("h ago") { return 3 }
                if lower.contains("day") || lower.contains("d ago") { return 4 }
                if lower.contains("week") || lower.contains("w ago") { return 5 }
                return 6
            }
            return score(t1.lastAccessed) < score(t2.lastAccessed)
        }
    }
    
    // MARK: - File Import Logic
    func importFile(url: URL, subject: String) {
        let fileManager = FileManager.default
        let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destURL = docDir.appendingPathComponent(url.lastPathComponent)
        
        do {
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            
            let accessing = url.startAccessingSecurityScopedResource()
            try fileManager.copyItem(at: url, to: destURL)
            if accessing { url.stopAccessingSecurityScopedResource() }
            
            let attr = try? fileManager.attributesOfItem(atPath: destURL.path)
            let fileSize = attr?[.size] as? Int64 ?? 0
            let sizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            
            let newSource = Source(
                name: url.lastPathComponent,
                fileType: url.pathExtension.uppercased(),
                size: sizeString
            )
            
            saveContent(subject: subject, content: newSource)
            
        } catch {
            print("❌ Error importing file: \(error)")
        }
    }
    
    // MARK: - Folder Management
    func addFolder(name: String) {
        if savedMaterials.keys.contains(name) { return }
        savedMaterials[name] = [
            DataManager.materialsKey: [],
            DataManager.sourcesKey: []
        ]
        saveToDisk()
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }
    
    func deleteFolder(name: String) {
        savedMaterials.removeValue(forKey: name)
        saveToDisk()
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }
    
    func createNewSubjectFolder(name: String) {
        addFolder(name: name)
    }
    
    func deleteSubjectFolder(name: String) {
        deleteFolder(name: name)
    }
    
    // MARK: - Persistence
    func saveToDisk() {
        let dataToSave = savedMaterials
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
        } catch {
            print("Error loading: \(error)")
        }
    }
    
    // MARK: - Topic Management
    func addTopic(to subjectName: String, topic: Topic) {
        let folder = subjectName.isEmpty ? "General Study" : subjectName
        
        if savedMaterials[folder] == nil {
            addFolder(name: folder)
        }
        
        var subjectData = savedMaterials[folder]!
        var materials = subjectData[DataManager.materialsKey] ?? []
        
        materials.removeAll { item in
            if case .topic(let t) = item {
                return t.name == topic.name && t.materialType == topic.materialType
            }
            return false
        }
        
        materials.append(.topic(topic))
        
        subjectData[DataManager.materialsKey] = materials
        savedMaterials[folder] = subjectData
        
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
        
        saveToDisk()
        
        Task {
            await SupabaseManager.shared.backupTopic(topic)
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
            addFolder(name: subject)
        }
        
        if segmentKey == DataManager.sourcesKey, let source = content as? Source {
            savedMaterials[subject]?[segmentKey]?.removeAll(where: { item in
                if case .source(let s) = item { return s.name == source.name }
                return false
            })
        }
        
        savedMaterials[subject]?[segmentKey]?.append(wrappedItem)
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
                // ✅ FIXED: Using 'notesContent' instead of 'studyNotes'
                if let notes = topic.notesContent, !notes.isEmpty {
                    return notes
                }
                if let oldContent = topic.largeContentBody, !oldContent.isEmpty {
                    return oldContent
                }
                return "No content available."
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
            
            Task {
                await SupabaseManager.shared.backupTopic(topic)
            }
        }
    }
    
    func updateTopicContent(subject: String, topicName: String, newText: String, type: String = "Notes") {
        guard var materials = savedMaterials[subject]?[DataManager.materialsKey] else { return }
        
        for (index, item) in materials.enumerated() {
            if case .topic(var topic) = item, topic.name == topicName {
                
                // ✅ FIXED: Using 'notesContent'
                if type == "Notes" {
                    topic.notesContent = newText
                } else {
                    topic.largeContentBody = newText
                }
                
                materials[index] = .topic(topic)
                
                savedMaterials[subject]?[DataManager.materialsKey] = materials
                saveToDisk()
                
                Task {
                    await SupabaseManager.shared.backupTopic(topic)
                }
                break
            }
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
                        Task { await SupabaseManager.shared.backupTopic(topic) }
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
    
    // MARK: - Defaults (✅ RESTORED LOGIC)
    private func setupDefaultData() {
        
        // 1. Calculus Data
        let calculusMaterials: [StudyItem] = [
            .topic(Topic(
                name: "Partial Derivatives",
                lastAccessed: "Just now",
                materialType: "Flashcards",
                parentSubjectName: "Calculus",
                largeContentBody: "What is a Partial Derivative?|A derivative of a function of several variables"
            )),
            .topic(Topic(
                name: "Taylor Series PDF",
                lastAccessed: "2 days ago",
                materialType: "Notes",
                parentSubjectName: "Calculus",
                notesContent: "Taylor Series represent functions as infinite sums of terms calculated from derivatives."
            ))
        ]
        
        let calculusSources: [StudyItem] = [
            .source(Source(name: "Taylor Series PDF", fileType: "PDF", size: "1.2 mb"))
        ]
        
        savedMaterials["Calculus"] = [DataManager.materialsKey: calculusMaterials, DataManager.sourcesKey: calculusSources]
        
        // 2. Big Data
        let bigDataMaterials: [StudyItem] = [
            .topic(Topic(
                name: "Hadoop Fundamentals",
                lastAccessed: "1h ago",
                materialType: "Notes",
                parentSubjectName: "Big Data",
                notesContent: "--- NOTES ---\nHadoop allows for the distributed processing of large data sets across clusters of computers."
            )),
            .topic(Topic(
                name: "NoSQL Databases",
                lastAccessed: "3d ago",
                materialType: "Quiz",
                parentSubjectName: "Big Data",
                largeContentBody: "Which NoSQL type is best for storing social media relationships?|Document|Key-Value|Graph|Column-family|2|Graph databases like Neo4j are designed specifically for relationship-heavy data."
            ))
        ]
        savedMaterials["Big Data"] = [DataManager.materialsKey: bigDataMaterials, DataManager.sourcesKey: []]
        
        // 3. Computer Networks
        let netMaterials: [StudyItem] = [
            .topic(Topic(
                name: "OSI Model",
                lastAccessed: "1 day ago",
                materialType: "Quiz",
                parentSubjectName: "Computer Networks",
                largeContentBody: "Which layer is responsible for routing packets?|Data Link|Transport|Network|Session|2|The Network layer (Layer 3) handles IP addressing."
            ))
        ]
        savedMaterials["Computer Networks"] = [DataManager.materialsKey: netMaterials, DataManager.sourcesKey: []]
        
        // 4. MMA
        let mmaMaterials: [StudyItem] = [
            .topic(Topic(
                name: "8051 Architecture",
                lastAccessed: "2 days ago",
                materialType: "Flashcards",
                parentSubjectName: "MMA",
                largeContentBody: "8051 Data Bus size?|8-bit.\nAddress Bus size?|16-bit."
            ))
        ]
        savedMaterials["MMA"] = [DataManager.materialsKey: mmaMaterials, DataManager.sourcesKey: []]
    }
}
// MARK: - Notification Definitions
extension Notification.Name {
    static let didUpdateStudyMaterials = Notification.Name("didUpdateStudyMaterials")
    static let didUpdateStudyFolders = Notification.Name("didUpdateStudyFolders")
}
