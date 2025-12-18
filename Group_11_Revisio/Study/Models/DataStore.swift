//
//  DataStore.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import Foundation

// DataManager.swift






class DataManager {
    
    static let materialsKey = "Materials"
    static let sourcesKey = "Sources"
    
  
    static let shared = DataManager()
    
   
    var savedMaterials: [String: [String: [Any]]] = [
        
        "Calculus": [
            DataManager.materialsKey: [
                Topic(name: "Partial Derivatives", lastAccessed: "2h ago", materialType: "Flashcards"),
                Topic(name: "Limits", lastAccessed: "7h ago", materialType: "Quiz"),
                Topic(name: "Applications of derivatives", lastAccessed: "Yesterday", materialType: "Notes"),
                Topic(name: "Indefinite integral", lastAccessed: "Thursday", materialType: "Flashcards"),
                Topic(name: "Area under functions", lastAccessed: "Monday", materialType: "Quiz"),
                Topic(name: "Series and Sequences", lastAccessed: "3 days ago", materialType: "Notes"),
                Topic(name: "Multivariable Calculus", lastAccessed: "4 days ago", materialType: "Cheatsheet")
            ],
            DataManager.sourcesKey: [
                Source(name: "Taylor Series PDF", fileType: "PDF", size: "1.2 mb"),
                Source(name: "Prof. Leonard Channel", fileType: "Video", size: "—"),
                Source(name: "Derivative Rules Cheat", fileType: "Link", size: "—")
            ]
        ],
        
        "Big Data": [
            DataManager.materialsKey: [
                Topic(name: "Hadoop Fundamentals", lastAccessed: "1h ago", materialType: "Notes"),
                Topic(name: "NoSQL Databases", lastAccessed: "3d ago", materialType: "Quiz"),
                Topic(name: "Spark Streaming", lastAccessed: "1 week ago", materialType: "Flashcards"),
                Topic(name: "Data Warehousing", lastAccessed: "2 weeks ago", materialType: "Notes")
            ],
            DataManager.sourcesKey: [
                Source(name: "Hadoop Docs", fileType: "Link", size: "—")
            ]
        ],
        
        "Swift Fundamentals": [
            DataManager.materialsKey: [
                Topic(name: "Optionals & Error Handling", lastAccessed: "5m ago", materialType: "Flashcards"),
                Topic(name: "Enums and Structs", lastAccessed: "10m ago", materialType: "Notes"),
                Topic(name: "Memory Management (ARC)", lastAccessed: "1 hour ago", materialType: "Quiz"),
                Topic(name: "Concurrency with Async/Await", lastAccessed: "2 days ago", materialType: "Cheatsheet")
            ],
            DataManager.sourcesKey: []
        ],
        
        "MMA": [
            DataManager.materialsKey: [
                Topic(name: "8051 Architecture", lastAccessed: "2 days ago", materialType: "Flashcards"),
                Topic(name: "Interrupt Handling", lastAccessed: "3 days ago", materialType: "Quiz"),
                Topic(name: "Assembly Programming", lastAccessed: "4 days ago", materialType: "Notes"),
                Topic(name: "Interface Peripherals", lastAccessed: "1 week ago", materialType: "Cheatsheet")
            ],
            DataManager.sourcesKey: [
                Source(name: "Assembly Guide", fileType: "PDF", size: "5.1 mb")
            ]
        ],
        
        "Computer Networks": [
            DataManager.materialsKey: [
                Topic(name: "OSI Model", lastAccessed: "1 day ago", materialType: "Quiz"),
                Topic(name: "TCP vs UDP", lastAccessed: "3 days ago", materialType: "Flashcards"),
                Topic(name: "Routing Protocols", lastAccessed: "1 week ago", materialType: "Notes")
            ],
            DataManager.sourcesKey: []
        ]
    ]
    
   
    func saveContent(subject: String, content: Any) {
        let segmentKey: String
        
        if content is Topic {
            segmentKey = DataManager.materialsKey
        } else if content is Source {
            segmentKey = DataManager.sourcesKey
        } else {
            print("Error: Attempted to save unknown content type.")
            return
        }
        
        
        if savedMaterials[subject] == nil {
            savedMaterials[subject] = [DataManager.materialsKey: [], DataManager.sourcesKey: []]
        }
        
        if let existingArray = savedMaterials[subject]![segmentKey] {
            var mutableArray = existingArray
            mutableArray.append(content)
            savedMaterials[subject]![segmentKey] = mutableArray
        } else {
            
            savedMaterials[subject]![segmentKey] = [content]
        }
        
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
    }
    func createNewSubjectFolder(name: String) {
        
        savedMaterials[name] = [
            DataManager.materialsKey: [],
            DataManager.sourcesKey: []
        ]
        
     
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }
    func deleteSubjectFolder(name: String) {
        
        savedMaterials.removeValue(forKey: name)
        
      
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }
    func renameSubject(oldName: String, newName: String) {
        guard oldName != newName else { return }
        guard let data = savedMaterials[oldName] else { return }
       
        savedMaterials[newName] = data
       
        savedMaterials.removeValue(forKey: oldName)
        
        // TODO: Persist changes to disk if needed
        // saveToDisk()
        
        
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }
    
    

    func deleteItems(subjectName: String, items: [Any]) {
        guard var subjectData = savedMaterials[subjectName] else {
            print("DataManager Error: Subject '\(subjectName)' not found.")
            return
        }

        
        var materials = subjectData[DataManager.materialsKey] ?? []
        var sources = subjectData[DataManager.sourcesKey] ?? []
        
        var itemsToDelete: [String] = []

        for item in items {
            if let topic = item as? Topic {
                
                materials.removeAll { ($0 as? Topic)?.name == topic.name }
                itemsToDelete.append(topic.name)
                
            } else if let source = item as? Source {
                
                sources.removeAll { ($0 as? Source)?.name == source.name }
                itemsToDelete.append(source.name)
            }
        }
        
        
        subjectData[DataManager.materialsKey] = materials
        subjectData[DataManager.sourcesKey] = sources
        savedMaterials[subjectName] = subjectData
        
        print("Deleted items in \(subjectName): \(itemsToDelete.joined(separator: ", "))")

      
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
    }
   
    func getDetailedContent(for subjectName: String, topicName: String) -> String {
     
        guard let subjectData = DataManager.shared.savedMaterials[subjectName],
              let materials = subjectData[DataManager.materialsKey] else {
            return "Material or Parent Subject not found."
        }
        
      
        if let topic = materials.first(where: { ($0 as? Topic)?.name == topicName }) as? Topic {
            
         
            
            
            if subjectName == "Calculus" {
                if topicName == "Multivariable Calculus" {
                    return """
                    Cheat Sheet for Multivariable Calculus:
                    1. Separable (1st Order): dx/dy = f(x)g(y)
                    Solution: \\(\\int g(y) dy = \\int f(x) dx + C\\)
                    
                    2. Applications of derivatives
                    Key applications include finding extrema (maximum/minimum) and calculating rates of change.
                    """
                } else if topicName == "Applications of derivatives" {
                  
                    return "NOTES: Applications of derivatives include finding critical points, optimization, L'Hôpital's Rule, and calculating related rates. These are core concepts for understanding change."
                }
            }
        
            if subjectName == "Big Data" && topicName == "Hadoop Fundamentals" {
               
                return "Big Data Notes: HADOOP FUNDAMENTALS\n\nHadoop is an open-source framework for storing and processing massive datasets. It is built on two core components:\n\n1. HDFS (Storage)\n2. MapReduce (Processing Model)\n\nThis framework enables distributed processing of large data sets across clusters of computers."
            }
            
            
            let baseMessage = "No custom detailed content is available for this item yet."
            let detail = "\n\nMaterial Type: \(topic.materialType)\nSubject: \(subjectName)"
            return "\(baseMessage)\nTopic: \(topicName)\n\(detail)"
        }
        
        return "Topic '\(topicName)' not found in the materials list."
    }
    func updateTopicContent(subject: String, topicName: String, newText: String) {
        
      
        print("Content updated for Topic: \(topicName) in Subject: \(subject). New text: [\(newText.prefix(30))...]")
        
                NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
    }
    
    
}


    extension Notification.Name {
       
        static let didUpdateStudyMaterials = Notification.Name("didUpdateStudyMaterials")
        
       
        static let didUpdateStudyFolders = Notification.Name("didUpdateStudyFolders")
    }

