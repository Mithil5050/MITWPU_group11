//
//  QuizData.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 11/12/25.
//

import Foundation
struct QuizQuestion {
    let questionText: String
    let answers: [String] // Array of 4 answer choices
    let correctAnswerIndex: Int // Index of the correct answer (0, 1, 2, or 3)
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
