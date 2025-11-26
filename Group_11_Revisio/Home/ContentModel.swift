//
//  ContentModel.swift
//  Group_11_Revisio
//
//  Created by Mithil on 26/11/25.
//

import Foundation

// Defines the structure for a single uploaded item.
struct UploadedContent: Identifiable {
    // Required to conform to Identifiable for modern UI like SwiftUI or Diffable Data Sources
    let id = UUID()
    
    let type: String       // e.g., "Document", "Media", "Link"
    let title: String      // The display name (e.g., "MyResume.pdf" or "Quick Note")
    let timestamp: Date    // When the content was created/uploaded
    let url: URL?          // Optional: file path or link URL
}
