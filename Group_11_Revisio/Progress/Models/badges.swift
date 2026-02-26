import Foundation
import UIKit

// MARK: - Badging Namespace to avoid global name collisions
struct Badging {
    // MARK: - Achievement Hierarchy
    enum BadgeTier: Int, Codable {
        case bronze = 1
        case silver = 2
        case gold = 3
    }

    // MARK: - Activity Categories
    enum BadgeCategory: String, Codable, CaseIterable {
        case globalXP = "Global Level" // Added to keep your existing XP logic
        case quizMaster = "Quiz Master"
        case flashGenius = "Flash Genius"
        case notesCreator = "Notes Creator"
        case cheatsheetPro = "Cheatsheet Pro"
        case questSeeker = "Quest Seeker"
        case wordFiller = "Word Filler"
        case connector = "Connector"
        case dailyWord = "Daily Word"
        case streakMaster = "Streak Master"
        case deepFocus = "Deep Focus"
        case socialScholar = "Social Scholar"
        case sourceMaster = "Source Master"
    }

    // MARK: - Badge Model
    struct Badge: Codable, Identifiable {
        let id: String
        let title: String
        let category: BadgeCategory
        let tier: BadgeTier
        let goalValue: Int
        let detail: String
        let earnedDate: Date?

        // ✅ READS FROM BOTH GLOBAL XP AND NEW COUNTERS
        var currentValue: Int {
            let stats = ProgressDataManager.shared
            switch category {
            case .globalXP: return stats.totalXP // Preserves your main XP logic
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

        var isEarned: Bool {
            return currentValue >= goalValue
        }

        var progress: Float {
            return min(Float(currentValue) / Float(goalValue), 1.0)
        }

        var imageAssetName: String {
            let categoryKey = category.rawValue.replacingOccurrences(of: " ", with: "").lowercased()
            let tierNames = ["bronze", "silver", "gold"]
            let tierKey = tierNames[tier.rawValue - 1]
            return "exora_\(categoryKey)_\(tierKey)"
        }
    }
}
