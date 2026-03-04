//
//  ProgressDataManager.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 14/01/26.

import Foundation
import UIKit

class ProgressDataManager {
    static let shared = ProgressDataManager()
    
    var history: [LogHistoryItem] = []
    let pointsPerLevel: Int = 100
    
    // Check if the user has earned any XP yet
    var hasEarnedAnyXP: Bool {
        return totalXP > 0
    }
    
    // MARK: - Persistent Properties (Global XP)
    var totalXP: Int {
        get { UserDefaults.standard.integer(forKey: "user_total_xp") }
        set {
            let oldLevel = currentLevel
            UserDefaults.standard.set(newValue, forKey: "user_total_xp")
            
            let newLevel = currentLevel
            if newLevel > oldLevel {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("UserLeveledUp"), object: nil, userInfo: ["level": newLevel])
                    NotificationCenter.default.post(name: .xpDidUpdate, object: nil)
                }
            }
            Task { await SupabaseManager.shared.syncXP(totalXP: newValue) }
        }
    }

    // MARK: - 🛠 DATA MEMBERS (Resolves all "no member" errors)
    var totalQuizzesDone: Int { get { UserDefaults.standard.integer(forKey: "stat_quizzes_done") } set { UserDefaults.standard.set(newValue, forKey: "stat_quizzes_done") } }
    var totalFlashcardsViewed: Int { get { UserDefaults.standard.integer(forKey: "stat_cards_viewed") } set { UserDefaults.standard.set(newValue, forKey: "stat_cards_viewed") } }
    var totalNotesGenerated: Int { get { UserDefaults.standard.integer(forKey: "stat_notes_gen") } set { UserDefaults.standard.set(newValue, forKey: "stat_notes_gen") } }
    var totalCheatsheetsGenerated: Int { get { UserDefaults.standard.integer(forKey: "stat_cheat_gen") } set { UserDefaults.standard.set(newValue, forKey: "stat_cheat_gen") } }
    var totalQuestsCompleted: Int { get { UserDefaults.standard.integer(forKey: "stat_quests_done") } set { UserDefaults.standard.set(newValue, forKey: "stat_quests_done") } }
    var totalWordFillsDone: Int { get { UserDefaults.standard.integer(forKey: "stat_wordfill_done") } set { UserDefaults.standard.set(newValue, forKey: "stat_wordfill_done") } }
    var totalConnectionsWon: Int { get { UserDefaults.standard.integer(forKey: "stat_connections_win") } set { UserDefaults.standard.set(newValue, forKey: "stat_connections_win") } }
    var totalDailyChallengesSolved: Int { get { UserDefaults.standard.integer(forKey: "stat_daily_solved") } set { UserDefaults.standard.set(newValue, forKey: "stat_daily_solved") } }
    var totalFocusSessions: Int { get { UserDefaults.standard.integer(forKey: "stat_focus_sessions") } set { UserDefaults.standard.set(newValue, forKey: "stat_focus_sessions") } }
    var totalMessagesSent: Int { get { UserDefaults.standard.integer(forKey: "stat_messages_sent") } set { UserDefaults.standard.set(newValue, forKey: "stat_messages_sent") } }
    var totalDocumentsUploaded: Int { get { UserDefaults.standard.integer(forKey: "stat_docs_uploaded") } set { UserDefaults.standard.set(newValue, forKey: "stat_docs_uploaded") } }

    // MARK: - Streak Logic
    var currentStreak: Int {
        get { UserDefaults.standard.integer(forKey: "user_current_streak") }
        set {
            UserDefaults.standard.set(newValue, forKey: "user_current_streak")
            DispatchQueue.main.async { NotificationCenter.default.post(name: .xpDidUpdate, object: nil) }
        }
    }
    
    private var lastActiveDate: Date? {
        get { UserDefaults.standard.object(forKey: "user_last_active_date") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "user_last_active_date") }
    }

    func updateDailyStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let lastActive = lastActiveDate, calendar.isDate(lastActive, inSameDayAs: today) { return }
        if let lastActive = lastActiveDate {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            currentStreak = calendar.isDate(lastActive, inSameDayAs: yesterday) ? (currentStreak + 1) : 1
        } else {
            currentStreak = 1
        }
        lastActiveDate = Date()
    }
    
    // MARK: - Level Math (Resolves error in MonthlyBadgeCell)
    var currentLevel: Int { (totalXP / pointsPerLevel) + 1 }
    var userLevel: Int { currentLevel }
    var currentLevelXP: Int { totalXP % pointsPerLevel }

    private init() { }
}

// ✅ Resolve '.xpDidUpdate' error in AwardsViewController
extension Notification.Name {
    static let xpDidUpdate = Notification.Name("xpDidUpdate")
}
