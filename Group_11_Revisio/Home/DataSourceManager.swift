//
//  DataSourceManager.swift
//  Group_11_Revisio
//
//  Created by Mithil on 26/11/25.
//

import Foundation

class DataSourceManager {
    
    // Singleton pattern: provides a single, shared access point to the data.
    static let shared = DataSourceManager()
    
    // Private initializer prevents other parts of the code from creating new instances.
    private init() {
        // Optional: Load initial data or saved data from disk here.
    }
    
    // The central repository for all uploaded content.
    // 'private(set)' means only this class can modify the array.
    private(set) var contentFeed: [UploadedContent] = []
    
    // MARK: - Public Methods
    
    /// Adds a new piece of content to the feed and sorts by timestamp.
    func addContent(content: UploadedContent) {
        contentFeed.append(content)
        
        // Optionally sort by newest first
        contentFeed.sort { $0.timestamp > $1.timestamp }
        
        // In a real app, you would notify the HomeCollectionViewController here
        // using NotificationCenter or delegation.
        
        print("New content added: \(content.title). Total items: \(contentFeed.count)")
    }
    
    /// Clears all stored data (useful for testing/resetting).
    func clearAllContent() {
        contentFeed.removeAll()
    }
}
