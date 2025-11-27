//
//  ContentModel.swift
//  Group_11_Revisio
//
//  Created by Mithil on 26/11/25.
//

import Foundation

// ContentModel.swift

struct StudyContent {
    let id = UUID() // Unique identifier for tracking
    let filename: String
    let fileType: String // e.g., "Document", "Text Input", "Image"
    let data: Data // Use Data to hold file contents or encoded text
    
    // Initializer for text input
    init(text: String) {
        self.filename = "Direct Text \(StudyContent.textCount + 1)"
        self.fileType = "Text Input"
        // Encode the string to Data
        self.data = text.data(using: .utf8) ?? Data()
        StudyContent.textCount += 1
    }
    
    // Simple counter to uniquely name text inputs
    static var textCount = 0
}
