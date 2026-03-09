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
    }

    // Badge Model

    struct Badge: Codable, Identifiable {
        let id: String
        let title: String
        let category: BadgeCategory
        let tier: BadgeTier
        let goalValue: Int
        let detail: String
        let earnedDate: Date?

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
        Badge(id: "qm_1",  title: "Novice",     category: .quizMaster,    tier: .bronze, goalValue: 5,   detail: "Finish 5 quizzes.",           earnedDate: nil),
        Badge(id: "qm_2",  title: "Master",     category: .quizMaster,    tier: .silver, goalValue: 25,  detail: "Finish 25 quizzes.",          earnedDate: nil),
        Badge(id: "qm_3",  title: "Legend",     category: .quizMaster,    tier: .gold,   goalValue: 50,  detail: "50 quizzes with >90% score.", earnedDate: nil),

        // Flash Genius
        Badge(id: "fg_1",  title: "Starter",       category: .flashGenius,   tier: .bronze, goalValue: 20,  detail: "Review 20 cards.",  earnedDate: nil),
        Badge(id: "fg_2",  title: "Genius",         category: .flashGenius,   tier: .silver, goalValue: 100, detail: "Review 100 cards.", earnedDate: nil),
        Badge(id: "fg_3",  title: "Memory Palace",  category: .flashGenius,   tier: .gold,   goalValue: 500, detail: "Review 500 cards.", earnedDate: nil),

        // Notes Creator
        Badge(id: "nc_1",  title: "Scribe",      category: .notesCreator,  tier: .bronze, goalValue: 5,   detail: "Generate 5 AI Notes.",   earnedDate: nil),
        Badge(id: "nc_2",  title: "Scholar",     category: .notesCreator,  tier: .silver, goalValue: 25,  detail: "Generate 25 AI Notes.",  earnedDate: nil),
        Badge(id: "nc_3",  title: "Chronicler",  category: .notesCreator,  tier: .gold,   goalValue: 100, detail: "Generate 100 AI Notes.", earnedDate: nil),

        // Cheatsheet Pro
        Badge(id: "cp_1",  title: "Minimalist",  category: .cheatsheetPro, tier: .bronze, goalValue: 5,  detail: "5 Cheatsheets.",  earnedDate: nil),
        Badge(id: "cp_2",  title: "Optimizer",   category: .cheatsheetPro, tier: .silver, goalValue: 20, detail: "20 Cheatsheets.", earnedDate: nil),
        Badge(id: "cp_3",  title: "Strategist",  category: .cheatsheetPro, tier: .gold,   goalValue: 50, detail: "50 Cheatsheets.", earnedDate: nil),

        //  Quest Seeker
        Badge(id: "qs_1",  title: "Adventurer",  category: .questSeeker,   tier: .bronze, goalValue: 10,  detail: "10 Side Quests.",  earnedDate: nil),
        Badge(id: "qs_2",  title: "Warrior",     category: .questSeeker,   tier: .silver, goalValue: 50,  detail: "50 Side Quests.",  earnedDate: nil),
        Badge(id: "qs_3",  title: "Conqueror",   category: .questSeeker,   tier: .gold,   goalValue: 200, detail: "200 Side Quests.", earnedDate: nil),

        //  Word Filler
        Badge(id: "wf_1",  title: "Typer",         category: .wordFiller,    tier: .bronze, goalValue: 10,  detail: "Finish 10 Word Fills.", earnedDate: nil),
        Badge(id: "wf_2",  title: "Linguist",       category: .wordFiller,    tier: .silver, goalValue: 50,  detail: "Finish 50 Word Fills.", earnedDate: nil),
        Badge(id: "wf_3",  title: "Lexicographer",  category: .wordFiller,    tier: .gold,   goalValue: 150, detail: "150 Word Fills.",       earnedDate: nil),

        //  Connector
        Badge(id: "con_1", title: "Linker",         category: .connector,     tier: .bronze, goalValue: 10,  detail: "Win 10 Connections.", earnedDate: nil),
        Badge(id: "con_2", title: "Pattern Finder",  category: .connector,     tier: .silver, goalValue: 50,  detail: "Win 50 games.",       earnedDate: nil),
        Badge(id: "con_3", title: "Mastermind",      category: .connector,     tier: .gold,   goalValue: 150, detail: "Win 150 games.",      earnedDate: nil),

        //  Daily Word
        Badge(id: "dw_1",  title: "Puzzler",  category: .dailyWord,     tier: .bronze, goalValue: 5,   detail: "Solve 5 Daily Words.",   earnedDate: nil),
        Badge(id: "dw_2",  title: "Solver",   category: .dailyWord,     tier: .silver, goalValue: 30,  detail: "Solve 30 Daily Words.",  earnedDate: nil),
        Badge(id: "dw_3",  title: "Enigma",   category: .dailyWord,     tier: .gold,   goalValue: 100, detail: "Solve 100 Daily Words.", earnedDate: nil),

        // Streak Master
        Badge(id: "sm_1",  title: "Habit",        category: .streakMaster,  tier: .bronze, goalValue: 3,  detail: "3-Day Streak.",  earnedDate: nil),
        Badge(id: "sm_2",  title: "Dedicated",    category: .streakMaster,  tier: .silver, goalValue: 7,  detail: "7-Day Streak.",  earnedDate: nil),
        Badge(id: "sm_3",  title: "Unstoppable",  category: .streakMaster,  tier: .gold,   goalValue: 30, detail: "30-Day Streak.", earnedDate: nil),

        //  Deep Focus
        Badge(id: "df_1",  title: "Initiate",    category: .deepFocus,     tier: .bronze, goalValue: 5,   detail: "5 Focus sessions.",   earnedDate: nil),
        Badge(id: "df_2",  title: "Deep Diver",  category: .deepFocus,     tier: .silver, goalValue: 30,  detail: "30 Focus sessions.",  earnedDate: nil),
        Badge(id: "df_3",  title: "Monk Mode",   category: .deepFocus,     tier: .gold,   goalValue: 100, detail: "100 Focus sessions.", earnedDate: nil),

        //  Social Scholar
        Badge(id: "ss_1",  title: "Team Player",   category: .socialScholar, tier: .bronze, goalValue: 20, detail: "Send 20 group messages.",   earnedDate: nil),
        Badge(id: "ss_2",  title: "Collaborator",  category: .socialScholar, tier: .silver, goalValue: 5,  detail: "Join 5 study groups.",      earnedDate: nil),
        Badge(id: "ss_3",  title: "Leader",        category: .socialScholar, tier: .gold,   goalValue: 10, detail: "Start group (10 members).", earnedDate: nil),

        //  Source Master
        Badge(id: "src_1", title: "Collector",  category: .sourceMaster,  tier: .bronze, goalValue: 10,  detail: "Upload 10 documents.",  earnedDate: nil),
        Badge(id: "src_2", title: "Archivist",  category: .sourceMaster,  tier: .silver, goalValue: 50,  detail: "Upload 50 documents.",  earnedDate: nil),
        Badge(id: "src_3", title: "Librarian",  category: .sourceMaster,  tier: .gold,   goalValue: 200, detail: "Upload 200 documents.", earnedDate: nil)
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
