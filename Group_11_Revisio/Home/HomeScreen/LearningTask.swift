import Foundation

// 1. Define the types (Matches your visual design needs)
enum TaskType {
    case quiz
    case notes
    case video
    case other
}

// 2. The Struct holding the complex data
struct LearningTask {
    let title: String
    let subtitle: String?       // Optional custom text
    let remainingModules: Int   // The counter (e.g. "5")
    let type: TaskType          // Determines the icon
}
