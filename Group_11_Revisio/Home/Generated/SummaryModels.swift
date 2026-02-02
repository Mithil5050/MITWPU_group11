import Foundation

// ✅ NEW: Dedicated struct for the Summary Screen
struct QuizSummaryItem {
    let questionText: String
    let userAnswerIndex: Int?
    let correctAnswerIndex: Int
    let allOptions: [String]
    let explanation: String
    var isCorrect: Bool
}
