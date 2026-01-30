import Foundation

// 1. Define the types
enum TaskType {
    case quiz
    case notes
    case video
    case flashcard // 🆕 Added Flashcard Type
    case other
}

struct LearningTask {
    let title: String
    let subtitle: String?
    let remainingModules: Int
    let type: TaskType
}
