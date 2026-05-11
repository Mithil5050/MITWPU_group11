//
//  BadgeData.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 08/03/26.
//


import Foundation
import UIKit

typealias Badge = Badging.Badge

struct Badging {

    // : - Enums

    enum BadgeTier: Int, Codable {
        case bronze = 1, silver = 2, gold = 3
    }

    enum BadgeCategory: String, Codable, CaseIterable {
        case globalXP       = "Global Level"
        case quizMaster     = "Quiz Master"
        case flashGenius    = "Flash Genius"
        case notesCreator   = "Notes Creator"
        case cheatsheetPro  = "Cheatsheet Pro"
        case questSeeker    = "Quest Seeker"
        case wordFiller     = "Word Filler"
        case connector      = "Connector"
        case dailyWord      = "Daily Word"
        case streakMaster   = "Streak Master"
        case deepFocus      = "Deep Focus"
        case socialScholar  = "Social Scholar"
        case sourceMaster   = "Source Master"
        
        var unitLabel: String {
            switch self {
            case .globalXP:      return "XP"
            case .quizMaster:    return "quizzes"
            case .flashGenius:   return "flashcards"
            case .notesCreator:  return "notes"
            case .cheatsheetPro: return "cheatsheets"
            case .questSeeker:   return "quests"
            case .wordFiller:    return "words"
            case .connector:     return "connections"
            case .dailyWord:     return "challenges"
            case .streakMaster:  return "days"
            case .deepFocus:     return "sessions"
            case .socialScholar: return "messages"
            case .sourceMaster:  return "documents"
            }
        }
    }

    // Badge Model

    struct Badge: Codable, Identifiable {
        let id: String
        let title: String
        let category: BadgeCategory
        let tier: BadgeTier
        let goalValue: Int
        let detail: String
        let pastTenseDetail: String?
        let earnedDate: Date?

        var displayDescription: String {
            if isEarned, let pastTense = pastTenseDetail {
                return pastTense
            }
            return detail
        }

        var currentValue: Int {
            let stats = ProgressDataManager.shared
            switch category {
            case .globalXP:      return stats.totalXP
            case .quizMaster:
                return tier == .gold ? stats.totalHighLevelQuizzes : stats.totalQuizzesDone
            case .flashGenius:   return stats.totalFlashcardsViewed
            case .notesCreator:  return stats.totalNotesGenerated
            case .cheatsheetPro: return stats.totalCheatsheetsGenerated
            case .questSeeker:   return stats.totalQuestsCompleted
            case .wordFiller:    return stats.totalWordFillsDone
            case .connector:     return stats.totalConnectionsWon
            case .dailyWord:     return stats.totalDailyChallengesSolved
            case .streakMaster:  return stats.currentStreak
            case .deepFocus:     return stats.totalFocusSessions
            case .socialScholar: return stats.totalMessagesSent
            case .sourceMaster:  return stats.totalDocumentsUploaded
            }
        }

        var isEarned: Bool { currentValue >= goalValue }
        var progress: Float { min(Float(currentValue) / Float(goalValue), 1.0) }
    }

    //Static Badge Data

    static let allMilestones: [Badge] = [

        // : Quiz Master
        Badge(id: "qm_1",  title: "Novice",     category: .quizMaster,    tier: .bronze, goalValue: 5,   detail: "Earn this badge when you successfully complete 5 study quizzes.",           pastTenseDetail: "You earned this badge by successfully completing 5 study quizzes!", earnedDate: nil),
        Badge(id: "qm_2",  title: "Master",     category: .quizMaster,    tier: .silver, goalValue: 25,  detail: "Earn this badge when you successfully complete 25 study quizzes.",          pastTenseDetail: "You earned this badge by successfully completing 25 study quizzes!", earnedDate: nil),
        Badge(id: "qm_3",  title: "Legend",     category: .quizMaster,    tier: .gold,   goalValue: 50,  detail: "Earn this badge when you successfully complete 50 study quizzes with a score of 90% or higher.", pastTenseDetail: "You earned this badge by successfully completing 50 high-score study quizzes!", earnedDate: nil),

        // Flash Genius
        Badge(id: "fg_1",  title: "Starter",       category: .flashGenius,   tier: .bronze, goalValue: 20,  detail: "Earn this badge when you review 20 active recall flashcards to master your memory.",  pastTenseDetail: "You earned this badge by reviewing 20 flashcards and mastering your memory!", earnedDate: nil),
        Badge(id: "fg_2",  title: "Genius",         category: .flashGenius,   tier: .silver, goalValue: 100, detail: "Earn this badge when you review 100 active recall flashcards to master your memory.", pastTenseDetail: "You earned this badge by reviewing 100 flashcards and mastering your memory!", earnedDate: nil),
        Badge(id: "fg_3",  title: "Memory Palace",  category: .flashGenius,   tier: .gold,   goalValue: 500, detail: "Earn this badge when you review 500 active recall flashcards to master your memory.", pastTenseDetail: "You earned this badge by reviewing 500 flashcards and mastering your memory!", earnedDate: nil),

        // Notes Creator
        Badge(id: "nc_1",  title: "Scribe",      category: .notesCreator,  tier: .bronze, goalValue: 5,   detail: "Earn this badge when you generate 5 AI-powered study notes.",   pastTenseDetail: "You earned this badge by generating 5 AI-powered study notes!", earnedDate: nil),
        Badge(id: "nc_2",  title: "Scholar",     category: .notesCreator,  tier: .silver, goalValue: 25,  detail: "Earn this badge when you generate 25 AI-powered study notes.",  pastTenseDetail: "You earned this badge by generating 25 AI-powered study notes!", earnedDate: nil),
        Badge(id: "nc_3",  title: "Chronicler",  category: .notesCreator,  tier: .gold,   goalValue: 100, detail: "Earn this badge when you generate 100 AI-powered study notes.", pastTenseDetail: "You earned this badge by generating 100 AI-powered study notes!", earnedDate: nil),

        // Cheatsheet Pro
        Badge(id: "cp_1",  title: "Minimalist",  category: .cheatsheetPro, tier: .bronze, goalValue: 5,  detail: "Earn this badge when you create 5 study cheatsheets.",  pastTenseDetail: "You earned this badge by creating 5 study cheatsheets!", earnedDate: nil),
        Badge(id: "cp_2",  title: "Optimizer",   category: .cheatsheetPro, tier: .silver, goalValue: 20, detail: "Earn this badge when you create 20 study cheatsheets.", pastTenseDetail: "You earned this badge by creating 20 study cheatsheets!", earnedDate: nil),
        Badge(id: "cp_3",  title: "Strategist",  category: .cheatsheetPro, tier: .gold,   goalValue: 50, detail: "Earn this badge when you create 50 study cheatsheets.", pastTenseDetail: "You earned this badge by creating 50 study cheatsheets!", earnedDate: nil),

        //  Quest Seeker
        Badge(id: "qs_1",  title: "Adventurer",  category: .questSeeker,   tier: .bronze, goalValue: 10,  detail: "Earn this badge when you complete 10 side quests.",  pastTenseDetail: "You earned this badge by completing 10 side quests!", earnedDate: nil),
        Badge(id: "qs_2",  title: "Warrior",     category: .questSeeker,   tier: .silver, goalValue: 50,  detail: "Earn this badge when you complete 50 side quests.",  pastTenseDetail: "You earned this badge by completing 50 side quests!", earnedDate: nil),
        Badge(id: "qs_3",  title: "Conqueror",   category: .questSeeker,   tier: .gold,   goalValue: 200, detail: "Earn this badge when you complete 200 side quests.", pastTenseDetail: "You earned this badge by completing 200 side quests!", earnedDate: nil),

        //  Word Filler
        Badge(id: "wf_1",  title: "Typer",         category: .wordFiller,    tier: .bronze, goalValue: 10,  detail: "Earn this badge when you finish 10 Word Fill exercises.", pastTenseDetail: "You earned this badge by finishing 10 Word Fill exercises!", earnedDate: nil),
        Badge(id: "wf_2",  title: "Linguist",       category: .wordFiller,    tier: .silver, goalValue: 50,  detail: "Earn this badge when you finish 50 Word Fill exercises.", pastTenseDetail: "You earned this badge by finishing 50 Word Fill exercises!", earnedDate: nil),
        Badge(id: "wf_3",  title: "Lexicographer",  category: .wordFiller,    tier: .gold,   goalValue: 150, detail: "Earn this badge when you finish 150 Word Fill exercises.",       pastTenseDetail: "You earned this badge by finishing 150 Word Fill exercises!", earnedDate: nil),

        //  Connector
        Badge(id: "con_1", title: "Linker",         category: .connector,     tier: .bronze, goalValue: 10,  detail: "Earn this badge when you win 10 Connections games.", pastTenseDetail: "You earned this badge by winning 10 Connections games!", earnedDate: nil),
        Badge(id: "con_2", title: "Pattern Finder",  category: .connector,     tier: .silver, goalValue: 50,  detail: "Earn this badge when you win 50 Connections games.",       pastTenseDetail: "You earned this badge by winning 50 Connections games!", earnedDate: nil),
        Badge(id: "con_3", title: "Mastermind",      category: .connector,     tier: .gold,   goalValue: 150, detail: "Earn this badge when you win 150 Connections games.",      pastTenseDetail: "You earned this badge by winning 150 Connections games!", earnedDate: nil),

        //  Daily Word
        Badge(id: "dw_1",  title: "Puzzler",  category: .dailyWord,     tier: .bronze, goalValue: 5,   detail: "Earn this badge when you solve 5 Daily Word challenges.",   pastTenseDetail: "You earned this badge by solving 5 Daily Word challenges!", earnedDate: nil),
        Badge(id: "dw_2",  title: "Solver",   category: .dailyWord,     tier: .silver, goalValue: 30,  detail: "Earn this badge when you solve 30 Daily Word challenges.",  pastTenseDetail: "You earned this badge by solving 30 Daily Word challenges!", earnedDate: nil),
        Badge(id: "dw_3",  title: "Enigma",   category: .dailyWord,     tier: .gold,   goalValue: 100, detail: "Earn this badge when you solve 100 Daily Word challenges.", pastTenseDetail: "You earned this badge by solving 100 Daily Word challenges!", earnedDate: nil),

        // Streak Master
        Badge(id: "sm_1",  title: "Habit",        category: .streakMaster,  tier: .bronze, goalValue: 3,  detail: "Earn this badge when you maintain a dedicated study habit for 3 consecutive days.",  pastTenseDetail: "You earned this badge by maintaining a dedicated study habit for 3 consecutive days!", earnedDate: nil),
        Badge(id: "sm_2",  title: "Dedicated",    category: .streakMaster,  tier: .silver, goalValue: 7,  detail: "Earn this badge when you maintain a dedicated study habit for 7 consecutive days.",  pastTenseDetail: "You earned this badge by maintaining a dedicated study habit for 7 consecutive days!", earnedDate: nil),
        Badge(id: "sm_3",  title: "Unstoppable",  category: .streakMaster,  tier: .gold,   goalValue: 30, detail: "Earn this badge when you maintain a dedicated study habit for 30 consecutive days.", pastTenseDetail: "You earned this badge by maintaining a dedicated study habit for 30 consecutive days!", earnedDate: nil),

        //  Deep Focus
        Badge(id: "df_1",  title: "Initiate",    category: .deepFocus,     tier: .bronze, goalValue: 5,   detail: "Earn this badge when you complete 5 deep focus sessions.",   pastTenseDetail: "You earned this badge by completing 5 deep focus sessions!", earnedDate: nil),
        Badge(id: "df_2",  title: "Deep Diver",  category: .deepFocus,     tier: .silver, goalValue: 30,  detail: "Earn this badge when you complete 30 deep focus sessions.",  pastTenseDetail: "You earned this badge by completing 30 deep focus sessions!", earnedDate: nil),
        Badge(id: "df_3",  title: "Monk Mode",   category: .deepFocus,     tier: .gold,   goalValue: 100, detail: "Earn this badge when you complete 100 deep focus sessions.", pastTenseDetail: "You earned this badge by completing 100 deep focus sessions!", earnedDate: nil),

        //  Social Scholar
        Badge(id: "ss_1",  title: "Team Player",   category: .socialScholar, tier: .bronze, goalValue: 20, detail: "Earn this badge when you send 20 group messages.",   pastTenseDetail: "You earned this badge by sending 20 group messages!", earnedDate: nil),
        Badge(id: "ss_2",  title: "Collaborator",  category: .socialScholar, tier: .silver, goalValue: 5,  detail: "Earn this badge when you join 5 study groups.",      pastTenseDetail: "You earned this badge by joining 5 study groups!", earnedDate: nil),
        Badge(id: "ss_3",  title: "Leader",        category: .socialScholar, tier: .gold,   goalValue: 10, detail: "Earn this badge when you start a group with 10 members.", pastTenseDetail: "You earned this badge by starting a group with 10 members!", earnedDate: nil),

        //  Source Master
        Badge(id: "src_1", title: "Collector",  category: .sourceMaster,  tier: .bronze, goalValue: 10,  detail: "Earn this badge when you upload 10 study documents.",  pastTenseDetail: "You earned this badge by uploading 10 study documents!", earnedDate: nil),
        Badge(id: "src_2", title: "Archivist",  category: .sourceMaster,  tier: .silver, goalValue: 50,  detail: "Earn this badge when you upload 50 study documents.",  pastTenseDetail: "You earned this badge by uploading 50 study documents!", earnedDate: nil),
        Badge(id: "src_3", title: "Librarian",  category: .sourceMaster,  tier: .gold,   goalValue: 200, detail: "Earn this badge when you upload 200 study documents.", pastTenseDetail: "You earned this badge by uploading 200 study documents!", earnedDate: nil)
    ]

// Image Mapping
    static func imageName(for badge: Badge) -> String? {
        switch badge.id {

        // Quiz Master
        case "qm_1": return "badge4_quiz_master"   // Novice
        case "qm_2": return "badge4_quiz_master"   // Master
        case "qm_3": return "badge4_quiz_master"   // Legend

        // Flash Genius
        case "fg_1": return "badge2_flash_genuis"  // Starter
        case "fg_2": return "badge2_flash_genuis"  // Genius
        case "fg_3": return "badge2_flash_genuis"  // Memory Palace

        
        case "nc_1": return "badge5_summary_genius"     // Scribe      full name)
        case "nc_2": return "badge5_summary_genius"     // Scholar
        case "nc_3": return "badge5_summary_genius"     // Chronicler

        // Cheatsheet Pro
        case "cp_1": return "badge3_cheatsheet_pro"   // Minimalist  (fill in full name)
        case "cp_2": return "badge3_cheatsheet_pro"   // Optimizer
        case "cp_3": return "badge3_cheatsheet_pro"   // Strategist

        // Quest Seeker
        case "qs_1": return "badge6_ultimate_grinder_lock"  // Adventurer  (fill in full name)
        case "qs_2": return "badge6_ultimate_grinder_lock"  // Warrior
        case "qs_3": return "badge6_ultimate_grinder_lock"  // Conqueror

        // Word Filler — add your asset name
        case "wf_1": return "badge7_plan_perfected"  // Typer
        case "wf_2": return "badge7_plan_perfected"  // Linguist
        case "wf_3": return "badge7_plan_perfected"  // Lexicographer

        // Connector — add your asset name
        case "con_1": return "badge7_plan_perfected"  // Linker
        case "con_2": return "badge7_plan_perfected"   // Pattern Finder
        case "con_3": return "badge7_plan_perfected"  // Mastermind

        // Daily Word — add your asset name
        case "dw_1": return "badge2_flash_genuis"   // Puzzler
        case "dw_2": return "badge2_flash_genuis"     // Solver
        case "dw_3": return "badge2_flash_genuis"      // Enigma

        // Streak Master
        case "sm_1": return "streak master 1"   // Habit
        case "sm_2": return "streak master 2"   // Dedicated
        case "sm_3": return "streak master 3"   // Unstoppable

        // Deep Focus — add your asset name
        case "df_1": return "badge6_ultimate_grinder_lock"    // Initiate
        case "df_2": return  "badge6_ultimate_grinder_lock"   // Deep Diver
        case "df_3": return "badge6_ultimate_grinder_lock"    // Monk Mode

        // Social Scholar — add your asset name
        case "ss_1": return "badge7_plan_perfected"   // Team Player
        case "ss_2": return "badge7_plan_perfected"     // Collaborator
        case "ss_3": return "badge7_plan_perfected"    // Leader

        // Source Master — add your asset name
        case "src_1": return "badge5_summary_genius"  // Collector
        case "src_2": return "badge5_summary_genius"   // Archivist
        case "src_3": return "badge5_summary_genius"  // Librarian

        default: return nil
        }
    }
}
