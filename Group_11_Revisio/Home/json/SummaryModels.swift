import Foundation

struct QuizSummaryItem {
    let questionText: String
    let userAnswerIndex: Int?
    let correctAnswerIndex: Int
    let allOptions: [String]
    let explanation: String
    var isCorrect: Bool
}
