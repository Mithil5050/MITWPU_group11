//
//  Models.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 14/12/25.
//

import Foundation
struct QuestionResultDetail {
    let questionText: String
    let wasCorrect: Bool
    let selectedAnswer: String?
    let correctAnswerFullText: String
    let isFlagged: Bool
    var correctOptionLetter: String {
            // Find the index right after the first character
            guard let firstChar = correctAnswerFullText.first else {
                return "N/A"
            }
            
            // Return just the first character as the option letter
            return String(firstChar)
        }
}
struct FinalQuizResult {
    let finalScore: Int
    let totalQuestions: Int
    let timeElapsed: TimeInterval
    let sourceName: String
    let details: [QuestionResultDetail]
}
