//
//  Topic.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import Foundation
// Topic.swift

// Assume your Topic struct definition is available:
struct Topic {
    let name: String
    let lastAccessed: String
    let materialType: String
    // Add this to make the Topic self-aware of its origin for full path lookup:
    var parentSubjectName: String?
    // And if storing content in the Topic itself:
    var largeContentBody: String?
}
