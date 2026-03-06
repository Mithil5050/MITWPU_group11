import Foundation

struct Topic: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var lastAccessed: String
    var materialType: String
    var parentSubjectName: String
    
    var quizQuestions: [QuizQuestion]?
    
    var largeContentBody: String?
    var notesContent: String?
    var cheatsheetContent: String?
    var attempts: [QuizAttempt]?
    
    var sourceName: String?
    var createdDate: String?

    var safeAttempts: [QuizAttempt] {
        return attempts ?? []
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case lastAccessed
        case materialType
        case parentSubjectName
        case quizQuestions
        case largeContentBody
        case notesContent
        case cheatsheetContent
        case attempts
        case sourceName
        case createdDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.lastAccessed = try container.decode(String.self, forKey: .lastAccessed)
        self.materialType = try container.decode(String.self, forKey: .materialType)
        self.parentSubjectName = try container.decode(String.self, forKey: .parentSubjectName)
        
        self.quizQuestions = try container.decodeIfPresent([QuizQuestion].self, forKey: .quizQuestions)
        self.largeContentBody = try container.decodeIfPresent(String.self, forKey: .largeContentBody)
        self.notesContent = try container.decodeIfPresent(String.self, forKey: .notesContent)
        self.cheatsheetContent = try container.decodeIfPresent(String.self, forKey: .cheatsheetContent)
        self.attempts = try container.decodeIfPresent([QuizAttempt].self, forKey: .attempts)
        self.sourceName = try container.decodeIfPresent(String.self, forKey: .sourceName)
        self.createdDate = try container.decodeIfPresent(String.self, forKey: .createdDate)
    }
    
    init(id: UUID = UUID(),
         name: String,
         lastAccessed: String = "Just now",
         materialType: String,
         parentSubjectName: String,
         quizQuestions: [QuizQuestion]? = nil,
         largeContentBody: String? = nil,
         notesContent: String? = nil,
         cheatsheetContent: String? = nil,
         attempts: [QuizAttempt]? = nil,
         sourceName: String? = nil,
         createdDate: String? = nil) {
        
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
        self.sourceName = sourceName
        self.createdDate = createdDate
    }
}

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
