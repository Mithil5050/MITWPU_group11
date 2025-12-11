//
//  QuizData.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 11/12/25.
//

import Foundation
// QuizData.swift (If you can edit this file)

struct QuizQuestion {
    let questionText: String
    let answers: [String]
    let correctAnswerIndex: Int
    var userAnswerIndex: Int? = nil
    var isFlagged: Bool = false
}

// Stores the list of questions for the quiz
struct QuizManager {
    static let quiz = [
        QuizQuestion(
            questionText: "What is the primary function of the Swift 'guard' statement?",
            answers: ["Conditional loop execution", "Early exit from a function", "Error handling (throws)", "Define a private variable"],
            correctAnswerIndex: 1
        ),
        QuizQuestion(
            questionText: "Which data structure operates on a Last-In, First-Out (LIFO) principle?",
            answers: ["Queue", "Array", "Stack", "Linked List"],
            correctAnswerIndex: 2
        ),
        QuizQuestion(
            questionText: "What is the key component for distributed storage in Hadoop?",
            answers: ["MapReduce", "YARN", "HDFS", "Hive"],
            correctAnswerIndex: 2
        )
        // Add all your unique quiz questions here!
    ]
}
