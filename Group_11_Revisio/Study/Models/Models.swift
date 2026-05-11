
import Foundation
struct QuestionResultDetail:Codable {
    let questionText: String
    let wasCorrect: Bool
    let selectedAnswer: String?
    let correctAnswerFullText: String
    let isFlagged: Bool
    var correctOptionLetter: String {
           
            guard let firstChar = correctAnswerFullText.first else {
                return "N/A"
            }

            return String(firstChar)
        }
}
struct FinalQuizResult:Codable{
    let finalScore: Int
    let totalQuestions: Int
    let timeElapsed: TimeInterval
    let sourceName: String
    let details: [QuestionResultDetail]
}
