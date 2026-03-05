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

    // MARK: - Level UI Helpers

    /// Whether the user has done anything yet (used by AwardsViewController)
    var hasEarnedAnyXP: Bool {
        return totalXP > 0 || userLevel > 1
    }

    /// XP the user currently holds toward the next level (the carry-over amount)
    var currentLevelXP: Int { return totalXP }

    /// Convenience alias so existing call-sites that read `currentLevel` still compile
    var currentLevel: Int { return userLevel }

    /// The XP cost required to complete the user's current level and advance
    var requiredXPForCurrentLevel: Int {
        return levelRequirements[userLevel] ?? 5000
    }

    /// Progress bar value in [0.0 … 1.0]
    ///
    /// Usage:
    ///   xpProgressBar.setProgress(ProgressDataManager.shared.progressToNextLevel, animated: true)
    var progressToNextLevel: Float {
        let required = requiredXPForCurrentLevel
        guard required > 0 else { return 1.0 }
        return min(Float(totalXP) / Float(required), 1.0)
    }

    /// Legacy alias — new code should prefer `requiredXPForCurrentLevel`
    var pointsPerLevel: Int { return requiredXPForCurrentLevel }

    // MARK: - Core Storage

    /// Carry-over XP toward the next level. Setting this persists to UserDefaults,
    /// posts .xpDidUpdate for UI refresh, and syncs to Supabase.
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

    // MARK: - Level Requirements Table

    private let levelRequirements: [Int: Int] = [
        1: 250, 2: 400, 3: 600,  4: 850,  5: 1200,
        6: 1700, 7: 2300, 8: 3000, 9: 3800, 10: 4700
    ]

    // MARK: - XP & Leveling

    /// Adds `amount` XP to the user's carry-over total, then resolves every
    /// level-up threshold in order, carrying the remainder forward.
    ///
    /// Example — user is Level 1 (costs 250 XP), currently has 200 XP, earns 100:
    ///   200 + 100 = 300. 300 >= 250 → level up to 2, carry 50.
    ///   50 < 400 (Level 2 cost) → stop. totalXP = 50, userLevel = 2.
    func addXP(amount: Int) {
        var carryXP = totalXP + amount
        var workingLevel = userLevel
        let startingLevel = workingLevel

        while let required = levelRequirements[workingLevel], carryXP >= required {
            carryXP -= required   // pay this level's cost
            workingLevel += 1     // advance
        }

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

    /// Legacy wrapper so existing call-sites that use `getRequiredXPForCurrentLevel()` still compile
    func getRequiredXPForCurrentLevel() -> Int {
        return requiredXPForCurrentLevel
    }

    // MARK: - Statistic Counters (Badge Triggers)

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

    // MARK: - Streak Logic

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

    /// Call this once per day when the user completes their daily activity.
    ///
    /// What it does:
    /// 1. Determines if the streak continues (consecutive day) or resets to 1.
    /// 2. Awards 100 XP for maintaining the streak (guarded so it only fires once per day).
    /// 3. Increments `totalDailyChallengesSolved` (which triggers badge checks).
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
            addXP(amount: 100)
        }

        totalDailyChallengesSolved += 1
    }

    // MARK: - Badge Tracking
    //
    // TWO DISTINCT STATES per badge:
    //
    // ── "BadgeUnlocked" (in progress) ──────────────────────────────────────────
    //    Fires the very FIRST time a user attempts a task in a category.
    //    Trigger: newValue == 1  (i.e. they just did the activity for the first time)
    //    Meaning: "This badge is now visible and in progress."
    //    Persisted in: `unlockedBadgeIDs`  (so it only fires once, ever)
    //
    // ── "BadgeEarned" (completed) ──────────────────────────────────────────────
    //    Fires when newValue exactly reaches a badge's goalValue for the first time.
    //    Trigger: newValue == badge.goalValue
    //    Meaning: "You completed the requirement — badge fully earned!"
    //    Persisted in: `earnedBadgeIDs`  (so it only fires once per badge)
    //
    // Neither event ever fires twice for the same badge.

    /// IDs of badges that have been unlocked (put in progress). Stored in UserDefaults.
    private var unlockedBadgeIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "unlocked_badge_ids") ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "unlocked_badge_ids") }
    }

    /// IDs of badges that have been fully earned (goal reached). Stored in UserDefaults.
    private var earnedBadgeIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "earned_badge_ids") ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "earned_badge_ids") }
    }

    private func checkBadgeUnlocks(for category: Badging.BadgeCategory, newValue: Int) {
        guard newValue > 0 else { return }

        // Get this category's badges sorted Bronze (1) → Silver (2) → Gold (3)
        let badgesInCategory = BadgeData.allMilestones
            .filter { $0.category == category }
            .sorted { $0.tier.rawValue < $1.tier.rawValue }

        var currentUnlocked = unlockedBadgeIDs
        var currentEarned   = earnedBadgeIDs

        for (index, badge) in badgesInCategory.enumerated() {
            guard badge.goalValue > 0 else { continue }

            // ── UNLOCK: badge becomes visible and enters "in progress" ───────
            //
            // Bronze  → unlocks on the very first attempt (newValue == 1).
            //           There is no prerequisite tier.
            //
            // Silver  → unlocks the moment Bronze is earned
            //           (newValue == bronze.goalValue).
            //
            // Gold    → unlocks the moment Silver is earned
            //           (newValue == silver.goalValue).
            //
            // In every case the unlock fires exactly once, guarded by unlockedBadgeIDs.
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

            // ── EARN: badge goal reached for the first time ──────────────────
            // Fires once when the stat counter exactly hits this badge's goalValue.
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

    private init() { }
}

extension Notification.Name {
    static let xpDidUpdate = Notification.Name("xpDidUpdate")
}
