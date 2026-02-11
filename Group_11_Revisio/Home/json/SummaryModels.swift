import Foundation

// ✅ Added ': Codable' conformance so it can be passed in Segue
struct QuizSummaryItem: Codable {
    let questionText: String
    let userAnswerIndex: Int?
    let correctAnswerIndex: Int
    let allOptions: [String]
    let explanation: String
    var isCorrect: Bool
}
