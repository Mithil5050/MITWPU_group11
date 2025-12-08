//
//  DataStore.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import Foundation

// DataManager.swift






class DataManager {
    // Define the required keys for segment access
    static let materialsKey = "Materials"
    static let sourcesKey = "Sources"
    
    // Singleton pattern to ensure global access to the same data
    static let shared = DataManager()
    
    // CORRECTED STRUCTURE: [Subject Name: [Segment Key (Materials/Sources): [Content (Topic/Source)]]]
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
    
    // NEW: Consolidated saving function that routes content to the correct segment
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
        
        // Ensure subject and segment structure exists before attempting to append
        if savedMaterials[subject] == nil {
            savedMaterials[subject] = [DataManager.materialsKey: [], DataManager.sourcesKey: []]
        }
        
        if let existingArray = savedMaterials[subject]![segmentKey] {
            var mutableArray = existingArray // Copy to mutable variable
            mutableArray.append(content)
            savedMaterials[subject]![segmentKey] = mutableArray
        } else {
            // Initialize the array if it doesn't exist yet
            savedMaterials[subject]![segmentKey] = [content]
        }
        
        NotificationCenter.default.post(name: .didUpdateStudyMaterials, object: nil)
    }
    func createNewSubjectFolder(name: String) {
        // 1. Initialize the new subject with empty Materials and Sources arrays
        // This uses the nested dictionary structure defined earlier: [Subject: [SegmentKey: [Content]]]
        savedMaterials[name] = [
            DataManager.materialsKey: [], // Initialize Materials as empty array
            DataManager.sourcesKey: []    // Initialize Sources as empty array
        ]
        
        // 2. Notify the Study screen (Master list) to reload its list of folders
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }
    func deleteSubjectFolder(name: String) {
        // 1. Remove the entire subject key and its nested data
        savedMaterials.removeValue(forKey: name)
        
        // 2. Notify any listeners (like the main Study tab if it were visible) that the folder list has changed
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }
    func renameSubject(oldName: String, newName: String) {
        guard oldName != newName else { return }
        guard let data = savedMaterials[oldName] else { return }
        // Save data under the new key
        savedMaterials[newName] = data
        // Remove data under the old key
        savedMaterials.removeValue(forKey: oldName)
        
        // TODO: Persist changes to disk if needed
        // saveToDisk()
        
        // Notify listeners that folder names changed
        NotificationCenter.default.post(name: .didUpdateStudyFolders, object: nil)
    }

    // REMOVED: The old addMaterial function is replaced by the more powerful saveContent
}

// Define the notification name used across the app

    extension Notification.Name {
        // FIX: Must use 'static let' instead of 'var'
        static let didUpdateStudyMaterials = Notification.Name("didUpdateStudyMaterials")
        
        // Ensure this is also correct if you have implemented folder creation logic:
        static let didUpdateStudyFolders = Notification.Name("didUpdateStudyFolders")
    }
// DataManager.swift (Conceptual)
