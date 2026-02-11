import Foundation

struct Topic: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var lastAccessed: String
    var materialType: String
    var parentSubjectName: String
    
    // ✅ ADDED: Dedicated storage for Quiz Questions
    var quizQuestions: [QuizQuestion]?
    
    // ✅ PRESERVED: Your original variable names
    var largeContentBody: String?
    var notesContent: String?
    var cheatsheetContent: String?
    var attempts: [QuizAttempt]?

    var safeAttempts: [QuizAttempt] {
        return attempts ?? []
    }
    
    // Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id, name, lastAccessed, materialType, parentSubjectName
        case quizQuestions // ✅ Added key
        case largeContentBody, notesContent, cheatsheetContent, attempts
    }
    
    // Decoder Init
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.lastAccessed = try container.decode(String.self, forKey: .lastAccessed)
        self.materialType = try container.decode(String.self, forKey: .materialType)
        self.parentSubjectName = try container.decode(String.self, forKey: .parentSubjectName)
        
        // Optional properties
        self.quizQuestions = try container.decodeIfPresent([QuizQuestion].self, forKey: .quizQuestions)
        self.largeContentBody = try container.decodeIfPresent(String.self, forKey: .largeContentBody)
        self.notesContent = try container.decodeIfPresent(String.self, forKey: .notesContent)
        self.cheatsheetContent = try container.decodeIfPresent(String.self, forKey: .cheatsheetContent)
        self.attempts = try container.decodeIfPresent([QuizAttempt].self, forKey: .attempts)
    }
    
    // Memberwise Init
    init(id: UUID = UUID(),
         name: String,
         lastAccessed: String = "Just now",
         materialType: String,
         parentSubjectName: String,
         quizQuestions: [QuizQuestion]? = nil, // ✅ Added parameter
         largeContentBody: String? = nil,
         notesContent: String? = nil,
         cheatsheetContent: String? = nil,
         attempts: [QuizAttempt]? = nil) {
        
        self.id = id
        self.name = name
        self.lastAccessed = lastAccessed
        self.materialType = materialType
        self.parentSubjectName = parentSubjectName
        self.quizQuestions = quizQuestions
        self.largeContentBody = largeContentBody
        self.notesContent = notesContent
        self.cheatsheetContent = cheatsheetContent
        self.attempts = attempts
    }
}

// Keep QuizAttempt exactly as it was
struct QuizAttempt: Codable {
    let id: UUID
    let date: Date
    let score: Int
    let totalQuestions: Int
    let summaryData: String
    
    var percentage: Double {
        return totalQuestions > 0 ? (Double(score) / Double(totalQuestions)) * 100 : 0.0
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
