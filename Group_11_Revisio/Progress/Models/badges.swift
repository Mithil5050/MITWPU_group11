import Foundation
import UIKit

typealias Badge = Badging.Badge

struct Badging {
    enum BadgeTier: Int, Codable {
        case bronze = 1, silver = 2, gold = 3
    }

    enum BadgeCategory: String, Codable, CaseIterable {
        case globalXP = "Global Level", quizMaster = "Quiz Master", flashGenius = "Flash Genius"
        case notesCreator = "Notes Creator", cheatsheetPro = "Cheatsheet Pro", questSeeker = "Quest Seeker"
        case wordFiller = "Word Filler", connector = "Connector", dailyWord = "Daily Word"
        case streakMaster = "Streak Master", deepFocus = "Deep Focus", socialScholar = "Social Scholar"
        case sourceMaster = "Source Master"
    }

    struct Badge: Codable, Identifiable {
        let id: String
        let title: String
        let category: BadgeCategory
        let tier: BadgeTier
        let goalValue: Int
        let detail: String
        let earnedDate: Date?

        // ✅ UPDATED: Points to the new exact member names in ProgressDataManager
        var currentValue: Int {
            let stats = ProgressDataManager.shared
            switch category {
            case .globalXP: return stats.totalXP
            case .quizMaster: return stats.totalQuizzesDone
            case .flashGenius: return stats.totalFlashcardsViewed
            case .notesCreator: return stats.totalNotesGenerated
            case .cheatsheetPro: return stats.totalCheatsheetsGenerated
            case .questSeeker: return stats.totalQuestsCompleted
            case .wordFiller: return stats.totalWordFillsDone
            case .connector: return stats.totalConnectionsWon
            case .dailyWord: return stats.totalDailyChallengesSolved
            case .streakMaster: return stats.currentStreak
            case .deepFocus: return stats.totalFocusSessions
            case .socialScholar: return stats.totalMessagesSent
            case .sourceMaster: return stats.totalDocumentsUploaded
            }
        }

        var isEarned: Bool { return currentValue >= goalValue }
        var progress: Float { return min(Float(currentValue) / Float(goalValue), 1.0) }
    }
}
