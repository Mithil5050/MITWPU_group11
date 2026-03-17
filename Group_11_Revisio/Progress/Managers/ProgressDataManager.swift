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


    // Count of fully earned badges — used by the Profile Badges card.
    var earnedBadgeCount: Int { return earnedBadgeIDs.count }

    // Whether the user has done anything yet (used by AwardsViewController)
    var hasEarnedAnyXP: Bool {
        return totalXP > 0 || userLevel > 1
    }
    // XP the user currently holds toward the next level (the carry-over amount)
    var currentLevelXP: Int { return totalXP }

    // Convenience alias so existing call-sites that read `currentLevel` still compile
    var currentLevel: Int { return userLevel }

    // The XP cost required to complete the user's current level and advance
    var requiredXPForCurrentLevel: Int {
        return levelRequirements[userLevel] ?? 5000
    }
    
    var progressToNextLevel: Float {
        let required = requiredXPForCurrentLevel
        guard required > 0 else { return 1.0 }
        return min(Float(totalXP) / Float(required), 1.0)
    }

    var pointsPerLevel: Int { return requiredXPForCurrentLevel }
    

    // Carry-over XP toward the next level.
    // posts .xpDidUpdate for UI refresh, and syncs to Supabase.
    var totalXP: Int {
        get { UserDefaults.standard.integer(forKey: "user_total_xp") }
        set {
            UserDefaults.standard.set(newValue, forKey: "user_total_xp")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .xpDidUpdate, object: nil)
            }
            Task { await SupabaseManager.shared.syncXP(totalXP: newValue) }
        }
    }

    var userLevel: Int {
        get {
            let lvl = UserDefaults.standard.integer(forKey: "user_current_level")
            return lvl == 0 ? 1 : lvl
        }
        set { UserDefaults.standard.set(newValue, forKey: "user_current_level") }
    }

    var todayXP: Int {
        get {
            let lastDate = UserDefaults.standard.object(forKey: "last_xp_date") as? Date ?? .distantPast
            if Calendar.current.isDateInToday(lastDate) {
                return UserDefaults.standard.integer(forKey: "today_xp_accumulated")
            }
            return 0
        }
        set {
            UserDefaults.standard.set(Date(), forKey: "last_xp_date")
            UserDefaults.standard.set(newValue, forKey: "today_xp_accumulated")
        }
    }


    private let levelRequirements: [Int: Int] = [
        1: 250, 2: 400, 3: 600,  4: 850,  5: 1200,
        6: 1700, 7: 2300, 8: 3000, 9: 3800, 10: 4700
    ]

   
    func addXP(amount: Int, reason: String = "XP Earned") {
        var carryXP = totalXP + amount
        var workingLevel = userLevel
        let startingLevel = workingLevel

        while let required = levelRequirements[workingLevel], carryXP >= required {
            carryXP -= required   // pay this level's cost
            workingLevel += 1     // advance
        }

        // Log the event in XP history
        recordXPEvent(reason, amount: amount)

        // Persist carry-over XP (fires .xpDidUpdate + Supabase sync via the setter)
        self.totalXP = carryXP

        // If level changed, persist and post a single "UserLeveledUp" notification
        if workingLevel > startingLevel {
            self.userLevel = workingLevel
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("UserLeveledUp"),
                    object: nil,
                    userInfo: ["level": workingLevel]
                )
            }
        }
    }

    // Legacy wrapper so existing call-sites that use `getRequiredXPForCurrentLevel()` still compile
    func getRequiredXPForCurrentLevel() -> Int {
        return requiredXPForCurrentLevel
    }

    // Counters (Badge Triggers)

    var totalQuizzesDone: Int {
        get { UserDefaults.standard.integer(forKey: "stat_quizzes_done") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_quizzes_done"); checkBadgeUnlocks(for: .quizMaster, newValue: newValue) }
    }
    var totalHighLevelQuizzes: Int {
        get { UserDefaults.standard.integer(forKey: "stat_high_quizzes") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_high_quizzes"); checkBadgeUnlocks(for: .quizMaster, newValue: newValue) }
    }
    var totalDailyChallengesSolved: Int {
        get { UserDefaults.standard.integer(forKey: "stat_daily_solved") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_daily_solved"); checkBadgeUnlocks(for: .dailyWord, newValue: newValue) }
    }
    var totalFlashcardsViewed: Int {
        get { UserDefaults.standard.integer(forKey: "stat_cards_viewed") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_cards_viewed"); checkBadgeUnlocks(for: .flashGenius, newValue: newValue) }
    }
    var totalNotesGenerated: Int {
        get { UserDefaults.standard.integer(forKey: "stat_notes_gen") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_notes_gen"); checkBadgeUnlocks(for: .notesCreator, newValue: newValue) }
    }
    var totalCheatsheetsGenerated: Int {
        get { UserDefaults.standard.integer(forKey: "stat_cheat_gen") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_cheat_gen"); checkBadgeUnlocks(for: .cheatsheetPro, newValue: newValue) }
    }
    var totalQuestsCompleted: Int {
        get { UserDefaults.standard.integer(forKey: "stat_quests_done") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_quests_done"); checkBadgeUnlocks(for: .questSeeker, newValue: newValue) }
    }
    var totalWordFillsDone: Int {
        get { UserDefaults.standard.integer(forKey: "stat_wordfill_done") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_wordfill_done"); checkBadgeUnlocks(for: .wordFiller, newValue: newValue) }
    }
    var totalConnectionsWon: Int {
        get { UserDefaults.standard.integer(forKey: "stat_connections_win") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_connections_win"); checkBadgeUnlocks(for: .connector, newValue: newValue) }
    }
    var totalFocusSessions: Int {
        get { UserDefaults.standard.integer(forKey: "stat_focus_sessions") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_focus_sessions"); checkBadgeUnlocks(for: .deepFocus, newValue: newValue) }
    }
    var totalMessagesSent: Int {
        get { UserDefaults.standard.integer(forKey: "stat_messages_sent") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_messages_sent"); checkBadgeUnlocks(for: .socialScholar, newValue: newValue) }
    }
    var totalDocumentsUploaded: Int {
        get { UserDefaults.standard.integer(forKey: "stat_docs_uploaded") }
        set { UserDefaults.standard.set(newValue, forKey: "stat_docs_uploaded"); checkBadgeUnlocks(for: .sourceMaster, newValue: newValue) }
    }

    // Streak Logic
    
    var currentStreak: Int {
        get { UserDefaults.standard.integer(forKey: "user_current_streak") }
        set {
            UserDefaults.standard.set(newValue, forKey: "user_current_streak")
            DispatchQueue.main.async { NotificationCenter.default.post(name: .xpDidUpdate, object: nil) }
            checkBadgeUnlocks(for: .streakMaster, newValue: newValue)
        }
    }

    private var lastStreakXPDate: Date? {
        get { UserDefaults.standard.object(forKey: "last_streak_xp_date") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "last_streak_xp_date") }
    }

    private var lastChallengeCompletionDate: Date? {
        get { UserDefaults.standard.object(forKey: "user_last_challenge_date") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "user_last_challenge_date") }
    }

    func completeDailyChallenge() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastChallengeCompletionDate {
            let lastStart = calendar.startOfDay(for: lastDate)

            // Guard: already completed today — do nothing
            if lastStart == today { return }

            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if calendar.isDate(lastStart, inSameDayAs: yesterday) {
                currentStreak += 1   // consecutive day — extend streak
            } else {
                currentStreak = 1    // gap in streak — reset
            }
        } else {
            currentStreak = 1        // first-ever completion
        }

        lastChallengeCompletionDate = today

        // Award 100 XP for today's streak day (once per calendar day)
        if let lastXPDate = lastStreakXPDate, calendar.isDate(lastXPDate, inSameDayAs: today) {
            // XP already awarded today — skip
        } else {
            lastStreakXPDate = today
            addXP(amount: 100, reason: "Streak Maintained")
        }

        totalDailyChallengesSolved += 1
    }

    // IDs of badges that have been unlocked (put in progress). Stored in UserDefaults.
    private var unlockedBadgeIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "unlocked_badge_ids") ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "unlocked_badge_ids") }
    }

    // IDs of badges that have been fully earned (goal reached). Stored in UserDefaults.
    private var earnedBadgeIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "earned_badge_ids") ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "earned_badge_ids") }
    }

    private func checkBadgeUnlocks(for category: Badging.BadgeCategory, newValue: Int) {
        guard newValue > 0 else { return }

        // Get this category's badges sorted Bronze (1) → Silver (2) → Gold (3)
        let badgesInCategory = Badging.allMilestones
            .filter { $0.category == category }
            .sorted { $0.tier.rawValue < $1.tier.rawValue }

        var currentUnlocked = unlockedBadgeIDs
        var currentEarned   = earnedBadgeIDs

        for (index, badge) in badgesInCategory.enumerated() {
            guard badge.goalValue > 0 else { continue }

            // ── UNLOCK: badge becomes visible and enters "in progress"
            let shouldUnlock: Bool
            if index == 0 {
                // Bronze: first ever attempt in this category
                shouldUnlock = (newValue == 1)
            } else {
                // Silver / Gold: previous tier's goal was just hit
                let previousBadge = badgesInCategory[index - 1]
                shouldUnlock = (newValue == previousBadge.goalValue)
            }

            if shouldUnlock && !currentUnlocked.contains(badge.id) {
                currentUnlocked.insert(badge.id)
                postBadgeEvent(badge: badge, type: "BadgeUnlocked")
            }

            // EARN: badge goal reached for the first time
        
            if newValue == badge.goalValue && !currentEarned.contains(badge.id) {
                currentEarned.insert(badge.id)
                postBadgeEvent(badge: badge, type: "BadgeEarned")
            }
        }

        // Persist both sets after processing all badges in the category
        unlockedBadgeIDs = currentUnlocked
        earnedBadgeIDs   = currentEarned
    }

    private func postBadgeEvent(badge: Badging.Badge, type: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("BadgeEvent"),
                object: nil,
                userInfo: ["badge": badge, "type": type]
            )
        }
    }

    //  XP History
    
    private(set) var xpHistory: [XPEvent] = {
        guard let data = UserDefaults.standard.data(forKey: "xp_history_v1"),
              let raw  = try? JSONDecoder().decode([[String: String]].self, from: data)
        else { return [] }

        let fmt = ISO8601DateFormatter()
        return raw.compactMap { dict -> XPEvent? in
            guard let desc   = dict["desc"],
                  let amtStr = dict["amt"],  let amt = Int(amtStr),
                  let dtStr  = dict["date"], let dt  = fmt.date(from: dtStr)
            else { return nil }
            return XPEvent(description: desc, amount: amt, date: dt)
        }
    }()

    
    func recordXPEvent(_ description: String, amount: Int) {
        let event = XPEvent(description: description, amount: amount, date: Date())
        xpHistory.insert(event, at: 0)
        if xpHistory.count > 50 { xpHistory = Array(xpHistory.prefix(50)) }
        persistXPHistory()
        // Sync this event to Supabase xp_log table
        Task { await SupabaseManager.shared.syncXPEvent(reason: description, amount: amount) }
    }

    // Session Logging for Progress Chart
    func logSession(minutes: Double, category: String) {
        let entry = LogHistoryItem(
            id: UUID().uuidString,
            amount: "\(Int(minutes))m",
            hours: minutes / 60.0,
            time: nil,
            date: Date(),
            category: category
        )
        history.append(entry)
        persistSessionHistory()
        NotificationCenter.default.post(name: .xpDidUpdate, object: nil)
    }

    private func persistSessionHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "session_history_v1")
        }
    }

    private func loadSessionHistory() {
        guard let data = UserDefaults.standard.data(forKey: "session_history_v1"),
              let loaded = try? JSONDecoder().decode([LogHistoryItem].self, from: data) else { return }
        history = loaded
    }

    private func persistXPHistory() {
        let fmt = ISO8601DateFormatter()
        let raw = xpHistory.map { ["desc": $0.description, "amt": "\($0.amount)", "date": fmt.string(from: $0.date)] }
        if let data = try? JSONEncoder().encode(raw) {
            UserDefaults.standard.set(data, forKey: "xp_history_v1")
        }
    }

    private init() { loadSessionHistory() }
}

extension Notification.Name {
    static let xpDidUpdate = Notification.Name("xpDidUpdate")
}
