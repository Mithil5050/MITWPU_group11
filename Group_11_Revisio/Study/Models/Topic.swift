//
//  Topic.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//
import Foundation
struct Topic: Codable {
    var name: String
    var lastAccessed: String
    var materialType: String
    var largeContentBody: String?
    var parentSubjectName: String
    var notesContent: String?
    var cheatsheetContent: String?
    var attempts: [QuizAttempt]?

    var safeAttempts: [QuizAttempt] {
        return attempts ?? []
    }
}
struct QuizAttempt: Codable {
    let id: UUID
    let date: Date
    let score: Int
    let totalQuestions: Int
    let summaryData: String
    
    var percentage: Double {
        return (Double(score) / Double(totalQuestions)) * 100
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
