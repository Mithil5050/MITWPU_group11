//
//  StudyContent.swift
//  Group_11_Revisio
//
//  Updated with Models for Study Plan & Today's Tasks
//

import Foundation

// MARK: - File Uploads
struct StudyContent: Codable {
    let id: UUID
    var filename: String
    
    init(filename: String) {
        self.id = UUID()
        self.filename = filename
    }
}

// MARK: - Shared Task Model
// Used by both Study Plan and Today's Task screens
struct PlanTask: Codable {
    let title: String
    let type: String // e.g., "Quiz", "Notes", "Revision"
    var isComplete: Bool
}

// MARK: - Study Plan Models (For StudyPlanViewController)
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

// MARK: - Today's Task Models (For TodaysTaskViewController)
struct TodaySubject: Codable {
    let subjectName: String
    let tasks: [PlanTask]
}
