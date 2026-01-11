//
//  StudyContent.swift
//  MITWPU_group11
//
//  Created by Mithil on 08/01/26.
//

import Foundation

// MARK: - Study Material (File Uploads)
struct StudyContent: Codable {
    let id: UUID
    var filename: String
    
    init(filename: String) {
        self.id = UUID()
        self.filename = filename
    }
}

// MARK: - Study Plan Models (JSON Data)

struct PlanTask: Codable {
    let title: String
    let type: String // e.g., "Quiz", "Notes", "Short Notes"
    var isComplete: Bool
}

struct PlanDay: Codable {
    let dayNumber: Int
    let tasks: [PlanTask]
}

struct PlanSubject: Codable {
    let id: String
    let name: String
    let nextTask: String
    let days: [PlanDay]
}
