//
//  UploadedContent.swift
//  Group_11_Revisio
//
//  Created by Mithil on 26/11/25.
//

import Foundation

struct UploadedContent: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let timestamp: Date

    init(id: UUID = UUID(), title: String, timestamp: Date = Date()) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
    }
}
